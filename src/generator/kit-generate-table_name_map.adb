with Kit.Schema.Tables;

with Aquarius.Drys.Blocks;
with Aquarius.Drys.Statements;

package body Kit.Generate.Table_Name_Map is

   ----------------------
   -- Generate_Package --
   ----------------------

   function Generate_Package
     (Db : in out Kit.Schema.Databases.Database_Type)
      return Aquarius.Drys.Declarations.Package_Type
   is
      Result : Aquarius.Drys.Declarations.Package_Type :=
                 Aquarius.Drys.Declarations. New_Package_Type
                   (Db.Ada_Name & ".Table_Names");

      procedure Generate_Table_Name
        (Table : Kit.Schema.Tables.Table_Type'Class);

      type Table_Function_Type is (Table_Name, Source_Name);

      function Table_Function
        (Function_Type : Table_Function_Type)
         return Aquarius.Drys.Declarations.Subprogram_Declaration'Class;

      -------------------------
      -- Generate_Table_Keys --
      -------------------------

      procedure Generate_Table_Name
        (Table : Kit.Schema.Tables.Table_Type'Class)
      is
         use Aquarius.Drys, Aquarius.Drys.Declarations;
      begin
         Result.Append
           (New_Deferred_Constant_Declaration
              (Table.Ada_Name,
               "Table_Reference",
               Object (Table.Index_Image)));
      end Generate_Table_Name;

      --------------------
      -- Table_Function --
      --------------------

      function Table_Function
        (Function_Type : Table_Function_Type)
         return Aquarius.Drys.Declarations.Subprogram_Declaration'Class
      is
         use Aquarius.Drys, Aquarius.Drys.Declarations;
         use Aquarius.Drys.Statements;
         Block : Aquarius.Drys.Blocks.Block_Type;

         Name  : constant String :=
                   (case Function_Type is
                       when Table_Name =>
                          "Table_Name",
                       when Source_Name =>
                          "Table_Source");
         Table_Case : Case_Statement_Record'Class :=
                        Case_Statement
                          ("Table");

         procedure Add_Table_Case
           (Table : Kit.Schema.Tables.Table_Type'Class);

         --------------------
         -- Add_Table_Case --
         --------------------

         procedure Add_Table_Case
           (Table : Kit.Schema.Tables.Table_Type'Class)
         is
            Seq : Sequence_Of_Statements;
            Result : constant String :=
                       (case Function_Type is
                           when Table_Name =>
                              Table.Ada_Name,
                           when Source_Name =>
                              Table.Standard_Name & ".adb");
         begin
            Seq.Append
              (Aquarius.Drys.Statements.New_Return_Statement
                 (Literal (Result)));
            Table_Case.Add_Case_Option
              (Value => Table.Index_Image,
               Stats => Seq);
         end Add_Table_Case;

      begin

         Db.Iterate (Add_Table_Case'Access);

         Block.Append (Table_Case);

         return Aquarius.Drys.Declarations.New_Function
           (Name        => Name,
            Argument    =>
              New_Formal_Argument
                ("Table", Named_Subtype ("Table_Reference")),
            Result_Type => "String",
            Block       => Block);
      end Table_Function;

   begin
      Result.Append
        (Aquarius.Drys.Declarations.New_Private_Type_Declaration
           ("Table_Reference",
            Aquarius.Drys.New_Derived_Type
              ("Positive range 1 .."
               & Integer'Image (Db.Table_Count))));

      Result.Append (Table_Function (Function_Type => Table_Name));
      Result.Append (Table_Function (Function_Type => Source_Name));

      Db.Iterate (Generate_Table_Name'Access);
      return Result;
   end Generate_Package;

end Kit.Generate.Table_Name_Map;
