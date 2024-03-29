with Ada.Command_Line;
with Ada.Directories;
with Ada.Exceptions;
with Ada.Text_IO;

with WL.Command_Line;

with Syn;
with Syn.File_Writer;
with Syn.Projects;

with Kit.Schema.Databases;
with Kit.Parser;
with Kit.XML_Reader;
with Kit.Generate;
with Kit.Import;

with Kit.Schema.Types;

with Kit.Generate.Leander_Module;
with Kit.Generate.Templates;

with Kit.Paths;

with GCS.Errors;

procedure Kit.Driver is
   Target_Directory : constant String :=
                        Ada.Directories.Current_Directory;
   Db               : Kit.Schema.Databases.Database_Type;

   Master_Options_Path  : constant String :=
                            Kit.Paths.Config_File ("default-options.txt");
   Local_Options_Path   : constant String :=
                            ".kit-options";
begin

   if not Ada.Directories.Exists (Local_Options_Path) then
      if Ada.Directories.Exists (Master_Options_Path) then
         Ada.Directories.Copy_File (Master_Options_Path, Local_Options_Path);
      else
         raise Constraint_Error with "cannot find configuration";
      end if;
   end if;

   WL.Command_Line.Load_Defaults (Local_Options_Path);

   if WL.Command_Line.Argument_Count /= 1 then
      Ada.Text_IO.Put_Line
        ("Usage: kit [options ...] <file or directory>");
      Ada.Command_Line.Set_Exit_Status (1);
      return;
   end if;

   Kit.Schema.Types.Create_Standard_Types;

   declare
      use Ada.Directories;
      File_Name : constant String :=
                    Ada.Command_Line.Argument (1);
      Extension : constant String :=
                    Ada.Directories.Extension (File_Name);
   begin
      Ada.Text_IO.Put_Line ("Reading: " & File_Name);
      if Extension = "xml" then
         Db := Kit.XML_Reader.Read_XML_File (File_Name);
      elsif Extension = "kit" or else Extension = "k3" then
         Db := Kit.Parser.Read_Kit_File (Ada.Command_Line.Argument (1));

         if GCS.Errors.Has_Errors then
            Ada.Command_Line.Set_Exit_Status (1);
            return;
         end if;
      elsif Ada.Directories.Kind (File_Name) =
        Ada.Directories.Directory
      then
         Db := Kit.Import.Import_Directory (File_Name);
      else
         Ada.Text_IO.Put_Line
           ("unknown file type: " & File_Name);
         Ada.Command_Line.Set_Exit_Status (2);
         return;
      end if;

   end;

   Ada.Text_IO.Put_Line ("Creating database");
   declare
      Project : constant Syn.Projects.Project :=
                  Kit.Generate.Generate_Database (Db);
      File    : Syn.File_Writer.File_Writer;
   begin
      Ada.Text_IO.Put_Line ("Writing source files");
      Syn.Projects.Write_Project (Project, File);
      Kit.Generate.Templates.Copy_Template_Packages
        (Db, Target_Directory);
      Kit.Generate.Leander_Module.Generate_Leander_Module
        (Db, Target_Directory);
   end;

   Ada.Text_IO.Put_Line ("Done");

exception
   when E : others =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         Ada.Exceptions.Exception_Message (E));
end Kit.Driver;
