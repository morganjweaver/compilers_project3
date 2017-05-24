using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using studio8;

namespace ASTBuilder
{
    class SemanticsVisitor : IReflectiveVisitor //IMPLEMENT PG 302
    {
        // This method is the key to implenting the Reflective Visitor pattern
        // in C#, using the 'dynamic' type specification to accept any node type.
        // The subsequent call to VisitNode does dynamic lookup to find the
        // appropriate Version.
        internal SymTbl_Stack symTable;

        public void Visit(dynamic node)
        {
            this.VisitNode(node);
        }

        // Call this method to begin the semantic checking process
        public void CheckSemantics(AbstractNode node)
        {
            symTable = new SymTbl_Stack();
            if (node == null) { 
                return;
            }
            node.Accept(this);
        }

        public void VisitChildren(AbstractNode node)
        {
            AbstractNode child = node.Child;
            while (child != null)
            {
                child.Accept(this);
                child = child.Sib;
            };
        }

        public void populateTypeSpec(Nodes.TypeSpec ts, ref SymInfo sim)
        {
            
            if (ts.isArray)
            {
                sim.isArray = true;
            }
            if (ts.Child.GetType() == typeof(Nodes.Primitive))
            {
                sim.pType = ((Nodes.Primitive)ts.Child).pType;
            }
            else if (ts.Child.GetType() == typeof(Nodes.QualName))
            {
                // e.g. compilers.symtable.Table -- i.e., reference to a named class
                sim.pType = Nodes.primType.CLASS;
                // suck name into
                sim.customTypeName = String.Join(".", ((Nodes.QualName)ts.Child).q_name);
            }
        }

        public void VisitNode(AbstractNode node)
        {
        }
        
        // Scope node
        public void VisitNode(Nodes.CompilationUnit node)
        {
            this.symTable.incrNestLevel();
            VisitChildren(node);
            Console.WriteLine("Printing CompilationUnit symtbl:");
            this.symTable.PrintTop();
            this.symTable.decrNestLevel();
        }

        // Scope node
        public void VisitNode(Nodes.ClassDeclaration node)
        {
            // Page 351
            // typeRef/ symbolTable WAT?
            node.symInfo.pType = Nodes.primType.CLASS;
            node.symInfo.customTypeName = node.name.name;
            node.symInfo.setTypesFromModifiers(node.modList);
            //this.symTable.lookup(node.name.name);
            this.symTable.enter(node.name.name, node.symInfo);
            this.symTable.incrNestLevel();
            VisitChildren(node.body); // Need to implement visitors for things in class bodies
            Console.WriteLine("Printing CLASS symtbl: " + node.name.name);
            this.symTable.PrintTop();
            this.symTable.decrNestLevel();   
        }
        public void VisitNode(Nodes.MethodDeclaration node) //METHOD DECLARATION
        {
            node.symInfo.setTypesFromModifiers(node.modList);
            node.symInfo.isMethod = true;
            populateTypeSpec(node.typeChild, ref node.symInfo); //RETURN TYPE
            this.symTable.enter(node.methodDeclarator.md_name, node.symInfo);
            this.symTable.incrNestLevel();
            VisitChildren(node.methodDeclarator); // Visit params
            VisitChildren(node.methodBody); // Visit bod
            Console.WriteLine("Printing METHOD symtbl: " + node.methodDeclarator.md_name);
            this.symTable.PrintTop();
            this.symTable.decrNestLevel();
            
        }
        //visit params
        public void VisitNode(Nodes.Parameter node) //typespec + decname in PARAMETER
        {
            this.populateTypeSpec(node.ts, ref node.symInfo);
            this.symTable.enter(node.name, node.symInfo);
        }
        //visit Nodes.Locals_and_Stmts
        public void VisitNode(Nodes.Locals_and_Stmts node) //other decls stored as children
        {
            VisitChildren(node);
        }
        public void VisitNode(Nodes.FieldDecls node) //other decls stored as children
        {
            VisitChildren(node);
        }
        public void VisitNode(Nodes.FieldDecl node) //other decls stored as children
        {
            VisitChildren(node);
        }
        public void VisitNode(Nodes.LocalFDOS node) //other decls stored as children
        {
            VisitChildren(node);
        }

        public void VisitNode(Nodes.FieldVarDecl node) //other decls stored as children
        {
            node.symInfo.setTypesFromModifiers(node.modList);
            this.populateTypeSpec(node.typeChild, ref node.symInfo);
            foreach(string name in node.fv_list)
            {
                this.symTable.enter(name, node.symInfo);
            }
        }
        public void VisitNode(Nodes.LocalVDS node) // local (inside scope), int x,y,z , etc
        {
            this.populateTypeSpec(node.typechild, ref node.symInfo);
            foreach (string name in node.varnames)
            {
                this.symTable.enter(name, node.symInfo);
            }
        }
    }
}
