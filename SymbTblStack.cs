﻿using System;
using System.Collections;
using System.Collections.Generic;
using ASTBuilder;

namespace studio8
{

    public class SymInfo
    {
        public string customTypeName; // if set, pType must not be
        public Nodes.primType pType;
        public List<Nodes.modType> mTypes = new List<Nodes.modType>();
        public bool isArray;
        public int arrLength;
        public bool isMethod = false; //if true, type returns a thing and TYPE IS RETURN TYPE
        
        // Takes list of modifiers and grabs the modTypes out and populates our list
        public void setTypesFromModifiers(List<Nodes.Modifiers> modNodes)
        {
            foreach (Nodes.Modifiers n in modNodes)
            {
                mTypes.Add(n.mod);
            }
        }
        
    }


    public class SymTbl_Stack : Symtab, SymtabInterface
    {

        /// <summary>
        /// Should never return a negative integer 
        /// </summary>
        protected static int nestLevel = 0;

        protected Stack<Hashtable> SymTblList = new Stack<Hashtable>();

        public override int CurrentNestLevel
        {
            get { return nestLevel;
            }
        }


        /// <summary>
        /// Opens a new scope, retaining outer ones </summary>

        public virtual void incrNestLevel()
        {
            Hashtable temp = new Hashtable();
            SymTblList.Push(temp);
            ++nestLevel;
        }

        /// <summary>
        /// Closes the innermost scope </summary>

        public virtual void decrNestLevel()
        {
            SymTblList.Pop(); //RemoveAt(nestLevel-1);
            --nestLevel;
        }

        /// <summary>
        /// Enter the given symbol information into the symbol table.  If the given
        ///    symbol is already present at the current nest level, do whatever is most
        ///    efficient, but do NOT throw any exceptions from this method.
        /// </summary>

        public virtual void enter(string s, SymInfo info)
        {
            if (SymTblList.Peek().ContainsKey(s))
            {
                Console.WriteLine("Already exists at this level; try another var name");
            }
            else
            {
                SymTblList.Peek().Add(s, info);
            }
        }

        /// <summary>
        /// Returns the information associated with the innermost currently valid
        ///     declaration of the given symbol.  If there is no such valid declaration,
        ///     return null.  Do NOT throw any excpetions from this method.
        /// </summary>

        public virtual SymInfo lookup(string s)
        {
            foreach (Hashtable h in SymTblList)
            {
                if (h.Contains(s))
                {
                    return (SymInfo) h[s];
                }
            }
            return null;
        }
        public void PrintTop()
        {
            foreach (string key in this.SymTblList.Peek().Keys)
            {
                for (int i = 0; i<nestLevel; i++)
                {
                    Console.Write("  ");
                }
                Console.WriteLine(String.Format("{0}:", key));// {1}", key, SymTblList.Peek()[key]));
            }
        }
    }
}