with Aquarius.Drys.Blocks;
with Aquarius.Drys.Expressions;
with Aquarius.Drys.Statements;

with Kit.Generate.Fetch;
with Kit.Names;

with Kit.Schema.Fields;
with Kit.Schema.Types;

package body Kit.Generate.Public_Get is

   ----------------------------------
   -- Create_Default_Key_Functions --
   ----------------------------------

   procedure Create_Default_Key_Functions
     (Table         : in     Kit.Schema.Tables.Table_Type'Class;
      Table_Package : in out Aquarius.Drys.Declarations.Package_Type'Class;
      Key           : in     Kit.Schema.Keys.Key_Type'Class)
   is
      use Aquarius.Drys.Declarations;
      Ask   : Aquarius.Drys.Expressions.Function_Call_Expression :=
                Aquarius.Drys.Expressions.New_Function_Call_Expression
                  ("First_By_" & Key.Ada_Name);
      Block : Aquarius.Drys.Blocks.Block_Type;
      Fn    : Subprogram_Declaration;
   begin

      for I in 1 .. Key.Field_Count loop
         declare
            Field : Kit.Schema.Fields.Field_Type'Class renames
                      Key.Field (I);
         begin
            Ask.Add_Actual_Argument
              (Aquarius.Drys.Object (Field.Ada_Name));
         end;
      end loop;

      Block.Add_Declaration
        (New_Constant_Declaration
           ("Item", Table.Type_Name, Ask));
      Block.Add_Statement
        (Aquarius.Drys.Statements.New_Return_Statement
           (Aquarius.Drys.Object ("Item.Has_Element")));

      Fn := New_Function
        ("Is_" & Key.Ada_Name,
         "Boolean",
         Block);

      for I in 1 .. Key.Field_Count loop
         declare
            Field : Kit.Schema.Fields.Field_Type'Class renames
                      Key.Field (I);
         begin
            Fn.Add_Formal_Argument
              (New_Formal_Argument
                 (Field.Ada_Name,
                  Aquarius.Drys.Named_Subtype
                    (Field.Get_Field_Type.Argument_Subtype)));
         end;
      end loop;

      Table_Package.Append (Fn);

      Table_Package.Append (Aquarius.Drys.Declarations.New_Separator);

   end Create_Default_Key_Functions;

   ---------------------------------
   -- Create_Generic_Get_Function --
   ---------------------------------

   procedure Create_Generic_Get_Function
     (Db            : in     Kit.Schema.Databases.Database_Type;
      Table         : in     Kit.Schema.Tables.Table_Type'Class;
      Table_Package : in out Aquarius.Drys.Declarations.Package_Type'Class;
      First         : in     Boolean;
      Key_Value     : in     Boolean)
   is
      pragma Unreferenced (Db);

      use Aquarius.Drys;
      use Aquarius.Drys.Declarations;
      Key_Case  : Aquarius.Drys.Statements.Case_Statement_Record'Class :=
                    Aquarius.Drys.Statements.Case_Statement ("Key");
      Block                  : Aquarius.Drys.Blocks.Block_Type;
      Fn                     : Subprogram_Declaration;

      Function_Name          : constant String :=
                                 (if First
                                  then "First_By"
                                  else "Last_By");

      procedure Process_Key (Base  : Kit.Schema.Tables.Table_Type'Class;
                             Key   : Kit.Schema.Keys.Key_Type'Class);

      -----------------
      -- Process_Key --
      -----------------

      procedure Process_Key (Base  : Kit.Schema.Tables.Table_Type'Class;
                             Key   : Kit.Schema.Keys.Key_Type'Class)
      is
         pragma Unreferenced (Base);
         use Aquarius.Drys.Expressions;
         Call : Function_Call_Expression :=
                  New_Function_Call_Expression
                    ("First_By_" &
                     Key.Ada_Name);
         Seq  : Aquarius.Drys.Statements.Sequence_Of_Statements;
      begin

         if Key_Value and then Key.Field_Count = 1 then
            Call.Add_Actual_Argument
              (Key.Field (1).Get_Field_Type.Convert_From_String ("Value"));
         end if;

         Seq.Append
           (Aquarius.Drys.Statements.New_Return_Statement
              (Call));
         Key_Case.Add_Case_Option ("K_" & Table.Ada_Name & "_"
                                   & Key.Ada_Name,
                                   Seq);
      end Process_Key;

   begin

      Key_Case.Add_Case_Option
        ("K_None",
         Aquarius.Drys.Statements.New_Return_Statement
           (Object ((if First then "First" else "Last"))));

      Table.Scan_Keys (Process_Key'Access);

      Block.Append (Key_Case);

      Fn := New_Function
        (Function_Name, Table.Type_Name,
         Block);

      Fn.Add_Formal_Argument
        ("Key", Table.Ada_Name & "_Key");

      if Key_Value then
         Fn.Add_Formal_Argument ("Value", "String");
      end if;

      Table_Package.Append (Fn);
      Table_Package.Append (Aquarius.Drys.Declarations.New_Separator);
   end Create_Generic_Get_Function;

   -------------------------
   -- Create_Get_Function --
   -------------------------

   procedure Create_Get_Function
     (Db            : in     Kit.Schema.Databases.Database_Type;
      Table         : in     Kit.Schema.Tables.Table_Type'Class;
      Key_Table     : in     Kit.Schema.Tables.Table_Type'Class;
      Table_Package : in out Aquarius.Drys.Declarations.Package_Type'Class;
      Scan          : in     Boolean;
      First         : in     Boolean;
      Key_Name      : in     String;
      Key_Value     : in     Boolean;
      Bounds        : in     Boolean)
   is
      pragma Unreferenced (Db);
      use Aquarius.Drys;
      use Aquarius.Drys.Expressions, Aquarius.Drys.Statements;

      Return_Sequence  : Sequence_Of_Statements;
      Lock_Sequence    : Sequence_Of_Statements;
      Invalid_Sequence : Sequence_Of_Statements;

      Using_Key : constant Boolean := Key_Name /= "";

      procedure Declare_Index
        (Block : in out Aquarius.Drys.Blocks.Block_Type);

      function Function_Name return String;

      procedure Set_Field
        (Seq        : in out Sequence_Of_Statements;
         Field_Name : String;
         Value      : Boolean);

      ------------------
      -- Declare_Index --
      ------------------

      procedure Declare_Index
        (Block : in out Aquarius.Drys.Blocks.Block_Type)
      is
         use Aquarius.Drys.Declarations;
      begin
         if not Scan then
            if not Using_Key then
               null;
--                 Block.Add_Declaration
--                   (New_Constant_Declaration
--                      ("Index",
--                       "Marlowe.Database_Index",
--                       Object ("Marlowe.Database_Index (Reference)")));
            else
               null;
            end if;
         else
            if not Using_Key then
               pragma Assert (First);
               Block.Add_Declaration (Use_Type ("Marlowe.Database_Index"));
               Block.Add_Declaration
                 (New_Object_Declaration
                    ("Index",
                     "Marlowe.Database_Index"));

               Block.Add_Statement ("Index := 1");
               declare
                  Valid_Index : constant Expression'Class :=
                                  New_Function_Call_Expression
                                    ("Marlowe.Btree_Handles.Valid_Index",
                                     "Marlowe_Keys.Handle",
                                     Table.Ada_Name & "_Table_Index",
                                     "Index");
                  Is_Deleted  : constant Expression'Class :=
                                  New_Function_Call_Expression
                                    ("Marlowe.Btree_Handles.Deleted_Record",
                                     "Marlowe_Keys.Handle",
                                     Table.Ada_Name & "_Table_Index",
                                     "Index");
                  Condition   : constant Expression'Class :=
                                  Operator ("and then",
                                            Valid_Index, Is_Deleted);
               begin
                  Block.Add_Statement
                    (While_Statement
                       (Condition,
                        New_Assignment_Statement
                          ("Index",
                          Operator ("+", Object ("Index"), Literal (1)))));
               end;

            else

               null;

            end if;
         end if;
      end Declare_Index;

      -------------------
      -- Function_Name --
      -------------------

      function Function_Name return String is

         Base_Name : constant String :=
                       (if not Scan
                        then "Get"
                        elsif not First
                        then "Last"
                        else "First");
      begin
         if Using_Key then
            return Base_Name & "_By_" & Kit.Names.Ada_Name (Key_Name);
         else
            return Base_Name;
         end if;
      end Function_Name;

      ---------------
      -- Set_Field --
      ---------------

      procedure Set_Field
        (Seq        : in out Sequence_Of_Statements;
         Field_Name : String;
         Value      : Boolean)
      is
      begin
         Seq.Append
           (New_Assignment_Statement
              ("Result." & Field_Name,
               (if Value then Object ("True") else Object ("False"))));
      end Set_Field;

   begin

      Return_Sequence.Append
        (New_Procedure_Call_Statement
           (Table.Ada_Name & "_Impl.File_Mutex.Shared_Lock"));

      if Using_Key then
         Return_Sequence.Append
           (Table.Ada_Name & "_Impl."
            & Kit.Names.Ada_Name (Key_Name)
            & "_Key_Mutex.Shared_Lock");
      end if;

      if not Scan then
         if not Using_Key then
            Return_Sequence.Append
              (New_Assignment_Statement
                 ("Result.Index",
                  Object ("Marlowe.Database_Index (Reference)")));
         else
            null;
         end if;
      else
         if not Using_Key then
            Return_Sequence.Append ("Result.Index := Index");
         else
            Lock_Sequence.Append
              (New_Assignment_Statement
                 ("Result.Key_Value",
                  Object
                    ("(K_" & Table.Ada_Name & "_"
                     & Kit.Names.Ada_Name (Key_Name)
                     & ", M)")));
            Lock_Sequence.Append
              (New_Assignment_Statement
                 ("Result.Index",
                  New_Function_Call_Expression
                    ("Marlowe.Key_Storage.To_Database_Index",
                     New_Function_Call_Expression
                       ("Marlowe.Btree_Handles.Get_Key",
                        "M"))));
         end if;
      end if;

      Fetch.Fetch_From_Index (Table       => Table,
                              Object_Name => "Result",
                              Target      => Lock_Sequence);

      Set_Field (Lock_Sequence, "Finished", not Scan);
      Set_Field (Lock_Sequence, "Forward", First);
      Set_Field (Lock_Sequence, "Using_Key", Using_Key);
      Set_Field (Lock_Sequence, "Using_Key_Value", Key_Value);
      Set_Field (Lock_Sequence, "Scanning", Scan);
      Set_Field (Lock_Sequence, "Link.S_Locked", True);

      Set_Field (Invalid_Sequence, "Finished", True);
      Set_Field (Invalid_Sequence, "Forward", False);
      Set_Field (Invalid_Sequence, "Scanning", False);
      Invalid_Sequence.Append ("Result.Index := 0");
      Set_Field (Invalid_Sequence, "Link.S_Locked", False);

      if not Using_Key then
         Return_Sequence.Append
           (If_Statement
              (New_Function_Call_Expression
                 ("Marlowe.Btree_Handles.Valid_Index",
                  "Marlowe_Keys.Handle",
                  Table.Ada_Name & "_Table_Index",
                  "Result.Index"),
               Lock_Sequence,
               Invalid_Sequence));
      else
         declare
            use Aquarius.Drys.Declarations;
            Mark_Block : Aquarius.Drys.Blocks.Block_Type;
         begin
            if Key_Value then
               declare
                  Key : constant Kit.Schema.Keys.Key_Type'Class :=
                          Table.Key (Key_Name);
                  Key_To_Storage : constant Expression'Class :=
                                     Table.To_Storage
                                       (Table, Key_Table, "", Key,
                                        With_Index => False);
                  First_To_Storage : constant Expression'Class :=
                                       Table.To_Storage
                                         (Table, Key_Table,
                                          "Start_", Key,
                                          With_Index => False);
                  Last_To_Storage  : constant Expression'Class :=
                                       Table.To_Storage
                                         (Table, Key_Table,
                                          "Finish_", Key,
                                          With_Index => False);
                  Start_Storage  : constant Expression'Class :=
                                     New_Function_Call_Expression
                                       ("Marlowe.Key_Storage.To_Storage_Array",
                                        "Marlowe.Database_Index'First");
                  Last_Storage   : constant Expression'Class :=
                                     New_Function_Call_Expression
                                       ("Marlowe.Key_Storage.To_Storage_Array",
                                        "Marlowe.Database_Index'Last");
                  Initialiser    : Function_Call_Expression :=
                                     New_Function_Call_Expression
                                       ("Marlowe.Btree_Handles.Search");
               begin
                  Initialiser.Add_Actual_Argument
                    (Object ("Marlowe_Keys.Handle"));
                  Initialiser.Add_Actual_Argument
                    (Object
                       ("Marlowe_Keys."
                        & Table.Key_Reference_Name (Key)));

                  if Bounds then
                     Initialiser.Add_Actual_Argument
                       (Operator ("&", First_To_Storage, Start_Storage));
                     Initialiser.Add_Actual_Argument
                       (Operator ("&", Last_To_Storage, Last_Storage));
                  else
                     Initialiser.Add_Actual_Argument
                       (Operator ("&", Key_To_Storage, Start_Storage));
                     Initialiser.Add_Actual_Argument
                       (Operator ("&", Key_To_Storage, Last_Storage));
                  end if;

                  Initialiser.Add_Actual_Argument
                    (Object ("Marlowe.Closed"));
                  Initialiser.Add_Actual_Argument
                    (Object ("Marlowe.Closed"));
                  Initialiser.Add_Actual_Argument
                    (Object
                       ((if First
                        then "Marlowe.Forward"
                        else "Marlowe.Backward")));
                  Mark_Block.Add_Declaration
                    (Use_Type ("System.Storage_Elements.Storage_Array"));
                  Mark_Block.Add_Declaration
                    (New_Constant_Declaration
                       ("M", "Marlowe.Btree_Handles.Btree_Mark",
                        Initialiser));
               end;

            else
               Mark_Block.Add_Declaration
                 (New_Constant_Declaration
                    ("M", "Marlowe.Btree_Handles.Btree_Mark",
                     New_Function_Call_Expression
                       ("Marlowe.Btree_Handles.Search",
                        "Marlowe_Keys.Handle",
                        "Marlowe_Keys."
                        & Table.Key_Reference_Name (Key_Name),
                        (if First
                         then "Marlowe.Forward"
                         else "Marlowe.Backward"))));
            end if;

            Mark_Block.Append
              (If_Statement
                 (New_Function_Call_Expression
                    ("Marlowe.Btree_Handles.Valid", "M"),
                  Lock_Sequence,
                  Invalid_Sequence));
            Return_Sequence.Append
              (Declare_Statement
                 (Mark_Block));
         end;
      end if;

      Return_Sequence.Append
        (New_Procedure_Call_Statement
           (Table.Ada_Name & "_Impl.File_Mutex.Shared_Unlock"));

      if Using_Key then
         Return_Sequence.Append
           (Table.Ada_Name & "_Impl." &
              Kit.Names.Ada_Name (Key_Name)
            & "_Key_Mutex.Shared_Unlock");
      end if;

      declare
         use Aquarius.Drys.Declarations;
         Block                  : Aquarius.Drys.Blocks.Block_Type;
         Fn                     : Subprogram_Declaration;
      begin
         Declare_Index (Block);
         Block.Append
           (Aquarius.Drys.Statements.New_Return_Statement
              ("Result", Table.Implementation_Name, Return_Sequence));

         Fn := New_Function
           (Function_Name, Table.Type_Name,
            Block);

         if not Scan and then not Using_Key then
            Fn.Add_Formal_Argument
              (New_Formal_Argument
                 ("Reference",
                  Named_Subtype (Table.Ada_Name & "_Reference")));
         end if;

         if Using_Key and then Key_Value then
            declare
               Key : constant Kit.Schema.Keys.Key_Type'Class :=
                       Table.Key (Key_Name);
            begin
               if Bounds then
                  for Is_Finish in Boolean loop
                     for I in 1 .. Key.Field_Count loop
                        declare
                           Tag   : constant String :=
                                     (if Is_Finish
                                      then "Finish_"
                                      else "Start_");
                           Field : Kit.Schema.Fields.Field_Type'Class
                           renames Key.Field (I);
                           Field_Type : Kit.Schema.Types.Kit_Type'Class
                                          renames Field.Get_Field_Type;
                        begin
                           if I = 1
                             or else Field_Type.Is_Table_Reference
                           then
                              Fn.Add_Formal_Argument
                                (New_Formal_Argument
                                   (Tag & Field.Ada_Name,
                                    Named_Subtype
                                      (Field_Type.Argument_Subtype)));
                           else
                              Fn.Add_Formal_Argument
                                (New_Formal_Argument
                                   (Tag & Field.Ada_Name,
                                    Named_Subtype
                                      (Field_Type.Argument_Subtype),
                                    Field_Type.First_Value));
                           end if;
                        end;
                     end loop;
                  end loop;
               else
                  for I in 1 .. Key.Field_Count loop
                     declare
                        Field : Kit.Schema.Fields.Field_Type'Class
                          renames Key.Field (I);
                     begin
                        Fn.Add_Formal_Argument
                          (New_Formal_Argument
                             (Field.Ada_Name,
                              Named_Subtype
                                (Field.Get_Field_Type.Argument_Subtype)));
                     end;
                  end loop;
               end if;
            end;
         end if;

         Table_Package.Append (Fn);
      end;

      Table_Package.Append (Aquarius.Drys.Declarations.New_Separator);
   end Create_Get_Function;

end Kit.Generate.Public_Get;
