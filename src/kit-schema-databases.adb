package body Kit.Schema.Databases is

   ------------
   -- Append --
   ------------

   procedure Append
     (Db   : in out Database_Type;
      Item : in     Kit.Schema.Tables.Table_Type'Class)
   is
   begin
      Db.Tables.Append (new Kit.Schema.Tables.Table_Type'Class'(Item));
   end Append;

   --------------
   -- Contains --
   --------------

   function Contains
     (Database : Database_Type;
      Name     : String)
      return Boolean
   is
   begin
      for T of Database.Tables loop
         if T.Name = Name then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   ---------------------
   -- Create_Database --
   ---------------------

   procedure Create_Database (Db   : in out Database_Type;
                              Name : in     String)
   is
   begin
      Kit.Names.Create (Kit.Names.Root_Named_Object (Db), Name);
   end Create_Database;

   -------------
   -- Element --
   -------------

   function Element
     (Position : Table_Cursor)
      return Kit.Schema.Tables.Table_Type'Class
   is
   begin
      return Table_Vectors.Element (Table_Vectors.Cursor (Position)).all;
   end Element;

   -------------
   -- Element --
   -------------

   function Element (Database : Database_Type;
                     Name     : String)
                     return Kit.Schema.Tables.Table_Type'Class
   is
   begin
      for T of Database.Tables loop
         if T.Name = Name then
            return T.all;
         end if;
      end loop;
      raise Constraint_Error with
        "table " & Name & " not found in database " & Database.Name;
   end Element;

   -------------
   -- Element --
   -------------

   function Element (Database : Database_Type;
                     Index    : Positive)
                     return Kit.Schema.Tables.Table_Type'Class
   is
   begin
      return Database.Tables.Element (Index).all;
   end Element;

   -----------------
   -- First_Table --
   -----------------

   function First_Table (Database : Database_Type) return Table_Cursor is
   begin
      return Table_Cursor (Database.Tables.First);
   end First_Table;

   -----------------
   -- Has_Element --
   -----------------

   overriding
   function Has_Element
     (Position : Table_Cursor)
      return Boolean
   is
   begin
      return Table_Vectors.Has_Element (Table_Vectors.Cursor (Position));
   end Has_Element;

   -------------
   -- Iterate --
   -------------

   procedure Iterate (Database : Database_Type;
                      Process  : not null access
                        procedure (Table : Kit.Schema.Tables.Table_Type'Class))
   is
      procedure Call_Process (Position : Table_Vectors.Cursor);

      ------------------
      -- Call_Process --
      ------------------

      procedure Call_Process (Position : Table_Vectors.Cursor) is
      begin
         Process (Table_Vectors.Element (Position).all);
      end Call_Process;

   begin
      Database.Tables.Iterate (Call_Process'Access);
   end Iterate;

   ----------
   -- Next --
   ----------

   overriding
   procedure Next (Position : in out Table_Cursor) is
   begin
      Table_Vectors.Next (Table_Vectors.Cursor (Position));
   end Next;

   -----------------
   -- Table_Count --
   -----------------

   function Table_Count (Db : Database_Type) return Natural is
   begin
      return Db.Tables.Last_Index;
   end Table_Count;

   -------------------
   -- With_Database --
   -------------------

   procedure With_Database (Db     : in out Database_Type'Class;
                            Withed : in     Database_Type'Class)
   is
   begin
      for T of Withed.Tables loop
         Db.Append (T.all);
      end loop;
   end With_Database;

end Kit.Schema.Databases;
