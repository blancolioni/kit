package body Kit.Server.Export is

   ------------
   -- Export --
   ------------

   procedure Export
     (Exporter : in out Root_Exporter'Class;
      Db       : Kit.Databases.Root_Database_Interface'Class)
   is
   begin
      Exporter.Start_Export (Db.Name);

      for Table_Index in 1 .. Db.Last_Table_Index loop
         declare
            Table : Kit.Databases.Root_Table_Interface'Class :=
                      Db.Table (Table_Index);
         begin
            Exporter.Start_Table (Table.Name);
            for Base_Index in 1 .. Table.Base_Count loop
               Exporter.Base_Table (Table.Base (Base_Index).Name);
            end loop;

            for Field_Index in 1 .. Table.Field_Count loop
               declare
                  Field : constant Kit.Databases.Root_Field_Interface'Class :=
                            Table.Field (Field_Index);
               begin
                  Exporter.Field (Name       => Field.Name,
                                  Field_Type => Field.Field_Type);
               end;
            end loop;
            Exporter.End_Table;
         end;
      end loop;

      Exporter.End_Export;
   end Export;

end Kit.Server.Export;
