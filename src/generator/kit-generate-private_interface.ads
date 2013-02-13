with Aquarius.Drys.Declarations;
with Kit.Schema.Databases;
with Kit.Schema.Tables;

package Kit.Generate.Private_Interface is

   function Generate_Private_Interface
     (Db    : in out Kit.Schema.Databases.Database_Type;
      Table : in     Kit.Schema.Tables.Table_Type'Class;
      Top   : in     Aquarius.Drys.Declarations.Package_Type'Class)
     return Aquarius.Drys.Declarations.Package_Type'Class;

end Kit.Generate.Private_Interface;
