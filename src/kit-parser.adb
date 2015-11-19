with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Doubly_Linked_Lists;
with Ada.Directories;

with GCS.Positions;

with Kit.Names;

with Kit.Parser.Tokens;                use Kit.Parser.Tokens;
with Kit.Parser.Lexical;               use Kit.Parser.Lexical;
with Kit.Paths;

with Kit.Schema.Fields;
with Kit.Schema.Keys;
with Kit.Schema.Tables;
with Kit.Schema.Types;
with Kit.Schema.Types.Enumerated;

package body Kit.Parser is

   System_Db : Kit.Schema.Databases.Database_Type;
   Got_System_Db : Boolean := False;

   package List_Of_Withed_Databases is
     new Ada.Containers.Indefinite_Doubly_Linked_Lists (String);

   procedure Read_Package
     (Db               : in out Kit.Schema.Databases.Database_Type;
      Package_Path     : String;
      Withed_Databases : in out List_Of_Withed_Databases.List;
      With_System      : Boolean;
      Create_Database  : Boolean);

   function At_Declaration return Boolean;

   procedure Parse_Record (Db : in out Kit.Schema.Databases.Database_Type)
     with Pre => Tok = Tok_Record;

   procedure Parse_Type_Declaration
     (Db : in out Kit.Schema.Databases.Database_Type)
     with Pre => Tok = Tok_Type;

   procedure Parse_Bases (Db    : Kit.Schema.Databases.Database_Type;
                          Table : Kit.Schema.Tables.Table_Type);

   function At_Field return Boolean;
   procedure Parse_Field (Db    : Kit.Schema.Databases.Database_Type;
                          Table : Kit.Schema.Tables.Table_Type);

   function At_Type return Boolean;
   function Parse_Type
     (Db           : Kit.Schema.Databases.Database_Type;
      Context_Name : String)
      return Kit.Schema.Types.Kit_Type;

   function Parse_Qualified_Identifier return String;

   procedure Parse_Field_Options
     (Field : Kit.Schema.Fields.Field_Type);

   --------------------
   -- At_Declaration --
   --------------------

   function At_Declaration return Boolean is
   begin
      return Tok = Tok_Record or else Tok = Tok_Type;
   end At_Declaration;

   --------------
   -- At_Field --
   --------------

   function At_Field return Boolean is
   begin
      return Tok = Tok_Identifier
        or else Tok = Tok_Key
        or else Tok = Tok_Unique;
   end At_Field;

   -------------
   -- At_Type --
   -------------

   function At_Type return Boolean is
   begin
      return Tok = Tok_Identifier or else Tok = Tok_Left_Paren;
   end At_Type;

   -----------------
   -- Parse_Bases --
   -----------------

   procedure Parse_Bases (Db    : Kit.Schema.Databases.Database_Type;
                          Table : Kit.Schema.Tables.Table_Type)
   is
   begin
      while Tok = Tok_Identifier loop
         if not Db.Contains (Tok_Text) then
            Error (Tok_Raw_Text & ": unknown record");
         else
            Table.Add_Base (Db.Element (Tok_Text));
         end if;
         Scan;
         exit when Tok /= Tok_Comma;
         Scan;
         if Tok /= Tok_Identifier then
            Error ("missing base record name");
            Skip_To ((Tok_Identifier, Tok_Is));
         end if;
      end loop;
   end Parse_Bases;

   -----------------
   -- Parse_Field --
   -----------------

   procedure Parse_Field (Db    : Kit.Schema.Databases.Database_Type;
                          Table : Kit.Schema.Tables.Table_Type)
   is
      Is_Key    : Boolean := False;
      Is_Unique : Boolean := False;
   begin
      if Tok = Tok_Unique then
         Is_Key := True;
         Is_Unique := True;
         Scan;
         if Tok = Tok_Key then
            Scan;
         else
            Error ("missing 'key'");
         end if;
      elsif Tok = Tok_Key then
         Is_Key := True;
         Scan;
      end if;

      if Tok /= Tok_Identifier then
         Error ("missing field name");
         Skip_To ((Tok_Semi, Tok_End));
         if Tok = Tok_Semi then
            Scan;
         end if;
         return;
      end if;

      declare
         Field_Name : constant String := Tok_Text;
      begin
         Scan;

         if Tok = Tok_With then
            Scan;

            declare
               Key : constant Kit.Schema.Keys.Key_Type :=
                       Kit.Schema.Keys.Create_Key
                         (Field_Name, Is_Unique);
            begin

               loop
                  if Table.Contains_Field (Tok_Text) then

                     Table.Add_Key_Field
                       (Key, Tok_Text);
                  else
                     Error ("table " & Table.Ada_Name
                            & " does not contain field "
                            & Tok_Raw_Text);
                  end if;
                  Scan;
                  exit when Tok /= Tok_Comma;
                  Scan;
                  if Tok /= Tok_Identifier then
                     Error ("extra ',' ignored");
                     exit;
                  end if;
               end loop;

               Table.Add_Key (Key);
            end;

         elsif Tok /= Tok_Colon then

            if Db.Contains (Field_Name) then

               declare
                  Field_Type : constant Kit.Schema.Types.Kit_Type :=
                                 Db.Element (Field_Name).Reference_Type;
                  Field      : constant Kit.Schema.Fields.Field_Type :=
                                 Kit.Schema.Fields.Create_Field
                                   (Field_Name, Field_Type);
               begin

                  if Tok = Tok_Is then
                     Scan;
                     Parse_Field_Options (Field);
                  end if;

                  Table.Append (Field);

                  if Is_Key then
                     if not Field_Type.Key_OK then
                        Error (Field_Name & ": type " & Field_Type.Name
                               & " cannot be used as a key");
                     end if;

                     declare
                        Key : constant Kit.Schema.Keys.Key_Type :=
                                Kit.Schema.Keys.Create_Key
                                  (Field_Name, Unique => Is_Unique);
                     begin
                        Table.Add_Key_Field (Key, Field_Name);
                        Table.Add_Key (Key);
                     end;
                  end if;

               end;
            else
               Error ("unknown table");
            end if;
         else

            Scan;

            if not At_Type then
               Error ("missing field type");
               Skip_To (Tok_Semi, Tok_End);
               if Tok = Tok_Semi then
                  Scan;
               end if;
               return;
            end if;

            declare
               Field_Type : constant Kit.Schema.Types.Kit_Type :=
                              Parse_Type (Db, Field_Name);
               Field      : constant Kit.Schema.Fields.Field_Type :=
                              Kit.Schema.Fields.Create_Field
                                (Field_Name, Field_Type);
            begin

               if Tok = Tok_Is then
                  Scan;
                  Parse_Field_Options (Field);
               end if;

               Table.Append (Item      => Field);
            end;

            if Is_Key then
               declare
                  Key : constant Kit.Schema.Keys.Key_Type :=
                          Kit.Schema.Keys.Create_Key
                            (Field_Name, Unique => Is_Unique);
               begin
                  Table.Add_Key_Field (Key, Field_Name);
                  Table.Add_Key (Key);
               end;
            end if;

         end if;

      end;

      if Tok = Tok_Semi then
         Scan;
      else
         Error ("missing ';'");
      end if;

   end Parse_Field;

   -------------------------
   -- Parse_Field_Options --
   -------------------------

   procedure Parse_Field_Options
     (Field : Kit.Schema.Fields.Field_Type)
   is
      Readable  : Boolean := False;
      Writeable : Boolean := False;
      Created   : Boolean := False;
   begin
      loop
         if Tok /= Tok_Identifier then
            Error ("missing field option");
            exit;
         else
            declare
               Option_Name : constant String := Tok_Text;
            begin
               if Option_Name = "readable" then
                  Readable := True;
               elsif Option_Name = "writeable" then
                  Writeable := True;
               elsif Option_Name = "created" then
                  Created := True;
               elsif Option_Name = "display" then
                  Field.Set_Display_Field;
               else
                  Error (Tok_Raw_Text & ": unknown field option");
               end if;
               Scan;
            end;
            exit when Tok /= Tok_Comma;
            Scan;
         end if;
      end loop;

      if Readable or else Writeable or else Created then
         Field.Set_Field_Options (Created, Readable, Writeable);
      end if;
   end Parse_Field_Options;

   --------------------------------
   -- Parse_Qualified_Identifier --
   --------------------------------

   function Parse_Qualified_Identifier return String is
      Result : constant String := Tok_Text;
   begin
      Scan;
      if Tok = Tok_Dot then
         Scan;
         return Result & "." & Parse_Qualified_Identifier;
      else
         return Result;
      end if;
   end Parse_Qualified_Identifier;

   ------------------
   -- Parse_Record --
   ------------------

   procedure Parse_Record (Db : in out Kit.Schema.Databases.Database_Type) is
   begin
      Scan;   --  Tok_Record

      if Tok /= Tok_Identifier then
         Error ("expected record name");
         Skip_To (Tok_End);
      else
         declare
            Record_Name : constant String := Tok_Text;
            Table       : constant Kit.Schema.Tables.Table_Type :=
                            Kit.Schema.Tables.Create_Table
                              (Record_Name);
         begin
            if Db.Contains (Record_Name) then
               Error (Record_Name & ": already defined");
            else
               Db.Append (Table);
            end if;

            Scan;

            if Record_Name /= "kit_root_record" then
               Table.Add_Base
                 (Db.Element ("kit_root_record"));
            end if;

            if Tok = Tok_Colon then
               Scan;
               Parse_Bases (Db, Table);
            end if;

            Table.Add_Base_Keys;

            if Tok = Tok_With then
               Scan;
               while Tok = Tok_Identifier loop
                  if Tok_Text = "vector" then
                     Table.Enable_Vector_Package;
                  elsif Tok_Text = "map" then
                     Table.Enable_Map_Package;
                  else
                     Error (Tok_Raw_Text & ": unknown table feature");
                  end if;
                  Scan;
                  if Tok = Tok_Comma then
                     Scan;
                     if Tok = Tok_Is or else Tok = Tok_Semi then
                        Error ("extra ',' ignored");
                     elsif Tok /= Tok_Identifier then
                        Error ("expected table feature identifier");
                     end if;
                  end if;
               end loop;
            end if;

            if Tok = Tok_Is then
               Scan;
               while At_Field loop
                  Parse_Field (Db, Table);
               end loop;

               Expect (Tok_End, Tok_End);

               if Tok = Tok_End then
                  Scan;
               end if;

               if Tok = Tok_Identifier then
                  if Tok_Text /= Record_Name then
                     Error ("Expected " & Kit.Names.Ada_Name (Record_Name));
                  end if;
                  Scan;
               elsif Tok = Tok_Record then
                  Error ("Use 'end "
                         & Kit.Names.Ada_Name (Record_Name)
                         & "' instead of 'end record'");
                  Scan;
               end if;
            end if;

            if Tok = Tok_Semi then
               Scan;
            else
               Error ("missing ';'");
               while Tok /= Tok_Semi
                 and then Tok /= Tok_Record
                 and then Tok /= Tok_End_Of_File
               loop
                  Scan;
               end loop;
               if Tok = Tok_Semi then
                  Scan;
               end if;
            end if;

         end;
      end if;

   end Parse_Record;

   ----------------
   -- Parse_Type --
   ----------------

   function Parse_Type
     (Db           : Kit.Schema.Databases.Database_Type;
      Context_Name : String)
      return Kit.Schema.Types.Kit_Type
   is
      Location : constant GCS.Positions.File_Position :=
                   Get_Current_Position;
   begin
      pragma Assert (At_Type);

      if Tok = Tok_Identifier then
         declare
            Name     : constant String := Tok_Text;
            Raw_Name : constant String := Tok_Raw_Text;
         begin
            Scan;

            if Kit.Schema.Types.Is_Type_Name (Name) then
               return Kit.Schema.Types.Get_Type (Name);
            elsif Name = "string" then
               if Tok /= Tok_Left_Paren
                 or else Next_Tok /= Tok_Integer_Constant
                 or else Next_Tok (2) /= Tok_Right_Paren
               then
                  Error ("missing constraint");
                  Skip_To (Tok_Semi, Tok_End);
                  return Kit.Schema.Types.Standard_String (32);
               end if;
               Scan;
               declare
                  Length : constant Natural := Natural'Value (Tok_Text);
               begin
                  Scan;
                  Scan;
                  return Kit.Schema.Types.Standard_String (Length);
               end;
            elsif Db.Contains (Name) then
               return Db.Element (Name).Reference_Type;
            else
               Error (Location, Raw_Name & ": no such type or record name");
               return Kit.Schema.Types.Standard_Integer;
            end if;
         end;
      elsif Tok = Tok_Left_Paren then
         declare
            Result : Kit.Schema.Types.Enumerated.Enumerated_Type;
         begin
            Result.Create (Context_Name);
            Scan;
            loop
               if Tok = Tok_Identifier then
                  Result.Add_Literal (Tok_Text);
                  Scan;
                  exit when Tok /= Tok_Comma;
                  Scan;
               else
                  Error ("missing enumerator literal");
                  Skip_To (Tok_Right_Paren, Tok_Semi, Tok_End);
                  exit;
               end if;
            end loop;

            if Tok = Tok_Right_Paren then
               Scan;
            else
               Error ("missing ')'");
            end if;

            return new Kit.Schema.Types.Enumerated.Enumerated_Type'(Result);
         end;
      else
         raise Program_Error with "expected to be at a type";
      end if;

   end Parse_Type;

   ----------------------------
   -- Parse_Type_Declaration --
   ----------------------------

   procedure Parse_Type_Declaration
     (Db : in out Kit.Schema.Databases.Database_Type)
   is
   begin
      Scan;  --  Tok_Type

      if Tok /= Tok_Identifier then
         Error ("expected a type name");
         Skip_To (Skip_To_And_Parse => (1 => Tok_Semi),
                  Skip_To_And_Stop  =>  (1 => Tok_End));
         return;
      end if;

      declare
         Name : constant String := Tok_Text;
      begin
         Scan;
         if Tok /= Tok_Is then
            Error ("missing 'is'");
            Skip_To (Skip_To_And_Parse => (1 => Tok_Semi),
                     Skip_To_And_Stop  =>  (1 => Tok_End));
            return;
         end if;

         Scan;

         declare
            New_Type : constant Kit.Schema.Types.Kit_Type :=
                         Parse_Type (Db, Name);
         begin
            Kit.Schema.Types.New_Type (New_Type);
         end;

         if Tok = Tok_Semi then
            Scan;
         else
            Error ("missing ';'");
         end if;
      end;

   end Parse_Type_Declaration;

   -------------------
   -- Read_Kit_File --
   -------------------

   procedure Read_Kit_File
     (Path : String;
      Db   : out Kit.Schema.Databases.Database_Type)
   is
      Withed : List_Of_Withed_Databases.List;
   begin

      Open (Path);

      Read_Package (Db, Path, Withed,
                    With_System     => True,
                    Create_Database => True);

      Close;
   end Read_Kit_File;

   ------------------
   -- Read_Package --
   ------------------

   procedure Read_Package
     (Db               : in out Kit.Schema.Databases.Database_Type;
      Package_Path     : String;
      Withed_Databases : in out List_Of_Withed_Databases.List;
      With_System      : Boolean;
      Create_Database  : Boolean)
   is
      Local_Withed_Databases : List_Of_Withed_Databases.List;
   begin

      while Tok = Tok_With loop
         Scan;
         while Tok = Tok_Identifier loop
            declare
               Name      : constant String :=
                             Ada.Characters.Handling.To_Lower
                               (Tok_Text)
                             & ".kit";
               Local_Path : constant String := Name;
               Related_Path : constant String :=
                                Ada.Directories.Compose
                                  (Ada.Directories.Containing_Directory
                                     (Package_Path),
                                   Name);

               System_Path : constant String :=
                               Kit.Paths.Config_Path
                               & "/packages/" & Name;
               Path        : constant String :=
                               (if Ada.Directories.Exists (Local_Path)
                                then Local_Path
                                elsif Ada.Directories.Exists (Related_Path)
                                then Related_Path
                                elsif Ada.Directories.Exists (System_Path)
                                then System_Path
                                else raise Constraint_Error
                                  with "not found: " & Name);
            begin
               if not Withed_Databases.Contains (Path) then
                  Local_Withed_Databases.Append (Path);
               end if;
            end;

            Scan;
            if Tok = Tok_Comma then
               Scan;
               Expect (Tok_Identifier, (Tok_Semi, Tok_Package));
            elsif Tok = Tok_Identifier then
               Error ("missing package name");
            elsif Tok /= Tok_Semi then
               Expect (Tok_Semi, (Tok_Package, Tok_With));
               exit;
            end if;
         end loop;

         if Tok = Tok_Semi then
            Scan;
         end if;
      end loop;

      if Tok /= Tok_Package then
         Error ("missing package");
      end if;

      Scan;

      declare
         Package_Name : constant String := Parse_Qualified_Identifier;
      begin
         Expect (Tok_Is, (Tok_Record, Tok_End));

         if Create_Database then
            Db.Create_Database (Package_Name);
         end if;

         if With_System and then Package_Name /= "kit.db" then
            if not Got_System_Db then
               declare
                  System_Path : constant String :=
                                  Kit.Paths.Config_Path & "/kit.kit";
               begin
                  Open (System_Path);
                  Read_Package (System_Db, System_Path,
                                Withed_Databases,
                                With_System => False,
                                Create_Database => True);
                  Close;
               end;
               Got_System_Db := True;
            end if;
            Db.With_Database (System_Db);
         end if;

         for Path of Local_Withed_Databases loop
            if not Withed_Databases.Contains (Path) then
               Withed_Databases.Append (Path);
               Open (Path);
               Read_Package
                 (Db               => Db,
                  Package_Path     => Path,
                  Withed_Databases => Withed_Databases,
                  With_System      => False,
                  Create_Database  => False);
               Close;
            end if;
         end loop;

         while At_Declaration loop
            if Tok = Tok_Record then
               Parse_Record (Db);
            elsif Tok = Tok_Type then
               Parse_Type_Declaration (Db);
            else
               pragma Assert (False);
            end if;
         end loop;

         Expect (Tok_End, Tok_End);

         if Tok = Tok_End then
            Scan;
         end if;

         if Tok = Tok_Identifier then
            declare
               Location     : constant GCS.Positions.File_Position :=
                                Get_Current_Position;
               Closing_Name : constant String := Parse_Qualified_Identifier;
            begin
               if Closing_Name /= Package_Name then
                  Error (Location, "expected " & Package_Name);
               end if;
            end;
         end if;

         if Tok = Tok_Semi then
            Scan;
         else
            Error ("missing ';'");
         end if;

         if Tok /= Tok_End_Of_File then
            Error ("extra tokens ignored");
         end if;
      end;
   end Read_Package;

end Kit.Parser;
