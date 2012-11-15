private with Ada.Containers.Indefinite_Vectors;
private with Ada.Finalization;
private with System.Storage_Elements;

package {database}.Tables is

   type Database_Table is tagged private;

   function Get_Table (Table_Name : String)
                       return Database_Table;

   function Has_Element (Table : Database_Table'Class) return Boolean;

   function Name (Table : Database_Table'Class) return String
   with Pre => Table.Has_Element;

   type Record_Reference is private;
   Null_Record_Reference : constant Record_Reference;
   function To_String (Reference : Record_Reference) return String;

   type Database_Record is tagged private;

   function Has_Element (Rec : Database_Record'Class) return Boolean;
   function Reference (Rec : Database_Record'Class) return Record_Reference;

   function Get (Table        : Database_Table'Class;
                 Reference    : Record_Reference)
                 return Database_Record;

   function Get (Table        : Database_Table'Class;
                 Key_Name     : String;
                 Key_Value    : String)
                 return Database_Record;

   function Field_Count (Rec : Database_Record'Class) return Natural;
   function Field_Name (Rec : Database_Record'Class;
                        Index : Positive)
                        return String;

   function Get
     (From_Record : Database_Record'Class;
      Field_Name  : String)
      return String;

   type Database_Field_Type is private;

   function Is_Integer (Field_Type : Database_Field_Type) return Boolean;
   function Is_Float (Field_Type : Database_Field_Type) return Boolean;
   function Is_Long_Float (Field_Type : Database_Field_Type) return Boolean;
   function Is_String (Field_Type : Database_Field_Type) return Boolean;
   function Is_Reference (Field_Type : Database_Field_Type) return Boolean;

   function Get_Field_Type
     (From_Record : Database_Record'Class;
      Field_Name  : String)
      return Database_Field_Type;

--     function Get_Table
--       (From_Record : Database_Record'Class;
--        Field_Name  : String)
--        return Database_Table;
--
--     function Get_Reference
--       (From_Record : Database_Record'Class;
--        Field_Name  : String)
--        return Record_Reference;

   procedure Iterate
     (Table        : Database_Table'Class;
      Key_Name     : String;
      Process      : not null access procedure
        (Item : Database_Record'Class));

   procedure Iterate
     (Table        : Database_Table'Class;
      Key_Name     : String;
      Key_Value    : String;
      Process      : not null access procedure
        (Item : Database_Record'Class));

   procedure Iterate
     (Table        : Database_Table'Class;
      Key_Name     : String;
      First        : String;
      Last         : String;
      Process      : not null access procedure
        (Item : Database_Record'Class));

   type Array_Of_References is array (Positive range <>) of Record_Reference;

   function Select_By
     (Table        : Database_Table'Class;
      Key_Name     : String;
      Key_Value    : String)
      return Array_Of_References;

private

   type Database_Table is tagged
      record
         Index : Marlowe.Table_Index;
      end record;

   type Record_Reference is new Marlowe.Database_Index;
   Null_Record_Reference : constant Record_Reference := 0;

   package Storage_Vectors is
     new Ada.Containers.Indefinite_Vectors
       (Positive,
        System.Storage_Elements.Storage_Array,
        System.Storage_Elements."=");

   type Database_Record is
     new Ada.Finalization.Controlled with
      record
         Table   : Marlowe.Table_Index;
         Index   : Marlowe.Database_Index;
         Rec_Ref : Kit_Record_Reference;
         Value   : Storage_Vectors.Vector;
      end record;

   type Database_Field_Type is
     (Integer_Type, Float_Type, Long_Float_Type, String_Type, Reference_Type);

end {database}.Tables;
