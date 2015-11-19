with Ada.Directories;

with XML.Parser;
with Kit.Import.XML_DB;

package body Kit.XML_Reader is

   -------------------
   -- Read_XML_File --
   -------------------

   function Read_XML_File
     (Path : String)
      return Kit.Schema.Databases.Database_Type
   is
      Db  : constant Kit.Schema.Databases.Database_Type :=
              Kit.Schema.Databases.Create_Database
                (Ada.Directories.Simple_Name (Path));
      Reader : XML.XML_Document'Class :=
                 Kit.Import.XML_DB.XML_DB_Reader (Db);
   begin
      XML.Parser.Run_Parser (Reader, Path);
      return Db;
   end Read_XML_File;

end Kit.XML_Reader;
