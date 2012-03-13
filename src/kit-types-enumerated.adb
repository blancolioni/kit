with Aquarius.Drys.Blocks;
with Aquarius.Drys.Declarations;
with Aquarius.Drys.Expressions;
with Aquarius.Drys.Statements;

package body Kit.Types.Enumerated is

   -----------------
   -- Add_Literal --
   -----------------

   procedure Add_Literal
     (To      : in out Enumerated_Type;
      Literal : String)
   is
   begin
      To.Literals.Append (Literal);
      if To.Literals.Last_Index = 2 then
         To.Size := 1;
      elsif To.Literals.Last_Index mod 256 = 0 then
         To.Size := To.Size + 1;
      end if;
   end Add_Literal;

   ----------------------------
   -- Create_Database_Record --
   ----------------------------

   function Create_Database_Record
     (For_Type : Enumerated_Type)
      return Aquarius.Drys.Statement'Class
   is
      use Aquarius.Drys;
      use Aquarius.Drys.Declarations;
      use Aquarius.Drys.Expressions;
      use Aquarius.Drys.Statements;
      T : Enumerated_Type'Class renames
            Enumerated_Type'Class (For_Type);
      Create : constant Expression'Class :=
                 New_Function_Call_Expression
                   ("Kit_Enumeration.Create",
                    Literal (Size (T)),
                    Literal (T.Ada_Name));
      Block        : Aquarius.Drys.Blocks.Block_Type;
   begin
      Block.Add_Declaration
        (New_Constant_Declaration
           ("Enum", "Kit_Enumeration_Reference",
            Create));
      for I in 1 .. T.Literals.Last_Index loop
         declare
            Create_Literal : Procedure_Call_Statement'Class :=
                               New_Procedure_Call_Statement
                                 ("Kit_Literal.Create");
         begin
            Create_Literal.Add_Actual_Argument
              (Literal (Kit.Names.Ada_Name (For_Type.Literals.Element (I))));
            Create_Literal.Add_Actual_Argument
              (Object ("Enum"));
            Create_Literal.Add_Actual_Argument (Literal (I - 1));

            Block.Append (Create_Literal);
         end;
      end loop;

      return Declare_Statement (Block);

   end Create_Database_Record;

   -------------------
   -- Default_Value --
   -------------------

   function Default_Value (Item : Enumerated_Type)
                           return Aquarius.Drys.Expression'Class
   is
   begin
      return Aquarius.Drys.Object
        (Kit.Names.Ada_Name (Item.Literals.Element (1)));
   end Default_Value;

   --------------------
   -- Return_Subtype --
   --------------------

   function Return_Subtype
     (Item : Enumerated_Type)
      return String
   is
   begin
      return Item.Ada_Name;
   end Return_Subtype;

   ----------
   -- Size --
   ----------

   function Size (Item : Record_Type_Enumeration) return Natural is
      pragma Unreferenced (Item);
   begin
      return 4;
   end Size;

   ----------------------------
   -- Storage_Array_Transfer --
   ----------------------------

   overriding
   function Storage_Array_Transfer
     (Item          : Enumerated_Type;
      To_Storage    : Boolean;
      Object_Name   : String;
      Storage_Name  : String;
      Start, Finish : System.Storage_Elements.Storage_Offset)
      return Aquarius.Drys.Statement'Class
   is
      Block : Aquarius.Drys.Blocks.Block_Type;
   begin
      if To_Storage then
         Block.Add_Declaration
           (Aquarius.Drys.Declarations.New_Constant_Declaration
              ("T", "Marlowe.Key_Storage.Unsigned_Integer",
               Aquarius.Drys.Object
                 (Item.Ada_Name & "'Pos (" & Object_Name & ")")));
      else
         Block.Add_Declaration
           (Aquarius.Drys.Declarations.New_Object_Declaration
              ("T", "Marlowe.Key_Storage.Unsigned_Integer"));
      end if;

      declare
         Proc_Name : constant String :=
                       (if To_Storage then "To" else "From")
                       & "_Storage";
      begin
         Block.Add_Statement
           (Storage_Array_Transfer
              (Item, "T",
               Storage_Name, Start, Finish,
               Proc_Name));
      end;

      if not To_Storage then
         Block.Add_Statement
           (Aquarius.Drys.Statements.New_Assignment_Statement
              (Object_Name,
               Aquarius.Drys.Object (Item.Ada_Name & "'Val (T)")));
      end if;

      return Aquarius.Drys.Statements.Declare_Statement (Block);

   end Storage_Array_Transfer;

   --------------------
   -- To_Declaration --
   --------------------

   overriding
   function To_Declaration
     (Item : Enumerated_Type)
      return Aquarius.Drys.Declaration'Class
   is
      Definition : Aquarius.Drys.Enumeration_Type_Definition;
   begin
      for Literal of Item.Literals loop
         Definition.New_Literal (Literal);
      end loop;
      return Aquarius.Drys.Declarations.New_Full_Type_Declaration
        (Item.Ada_Name, Definition);
   end To_Declaration;

   ----------------------
   -- To_Storage_Array --
   ----------------------

   function To_Storage_Array
     (Item        : Enumerated_Type;
      Object_Name : String)
      return Aquarius.Drys.Expression'Class
   is
      use Aquarius.Drys, Aquarius.Drys.Expressions;
   begin
      return New_Function_Call_Expression
        ("Marlowe.Key_Storage.To_Storage_Array",
         New_Function_Call_Expression
           (Item.Ada_Name & "'Pos",
            Object_Name),
         Literal (Size (Kit_Type'Class (Item))));
   end To_Storage_Array;

end Kit.Types.Enumerated;
