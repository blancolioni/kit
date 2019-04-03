with System.Storage_Elements;

with Marlowe;

package Kit.SQL.Database is

   type Table_Reference is private;

   function Get_Table (Name : String) return Table_Reference;
   function Get_Name (Table : Table_Reference) return String;
   function Get_Field_Count (Table : Table_Reference) return Natural;

   type Record_Reference is private;

   function Get_Record_Reference
     (Table : Table_Reference;
      Index : Marlowe.Database_Index)
      return Record_Reference;

   function Get_Field_Value
     (Reference : Record_Reference;
      Index     : Positive)
      return String;

   function Get_Field_Value
     (Reference : Record_Reference;
      Name      : String)
      return String;

   type Field_Reference is private;

   No_Field : constant Field_Reference;

   function Get_Field
     (Table : Table_Reference;
      Index : Positive)
      return Field_Reference;

   function Get_Field
     (Table : Table_Reference;
      Name  : String)
      return Field_Reference;

   function Get_Field_Name
     (Reference : Field_Reference)
      return String;

   function Get_Field_Value
     (Reference : Record_Reference;
      Field     : Field_Reference)
      return String;

   type Key_Reference is private;

   function Get_Key
     (Table : Table_Reference;
      Name  : String)
      return Key_Reference;

   function Get_Key_Length
     (Key : Key_Reference)
      return System.Storage_Elements.Storage_Count;

   function Get_Minimum
     (Key : Key_Reference)
      return System.Storage_Elements.Storage_Array;

   function Get_Maximum
     (Key : Key_Reference)
      return System.Storage_Elements.Storage_Array;

   function Get_Default_Key
     (Table : Table_Reference)
      return Key_Reference;

   function Get_Default_Field_Key
     (Field : Field_Reference)
      return Key_Reference;

   type Field_Reference_Array is array (Positive range <>) of Field_Reference;

   function Get_Key_Fields
     (Key : Key_Reference)
      return Field_Reference_Array;

   function Is_Field_Key
     (Key   : Key_Reference;
      Field : Field_Reference)
      return Boolean;

   function Contains_Field
     (Key   : Key_Reference;
      Field : Field_Reference)
      return Boolean;

   procedure Scan
     (Table       : Table_Reference;
      Key         : Key_Reference;
      Min_Value   : System.Storage_Elements.Storage_Array;
      Max_Value   : System.Storage_Elements.Storage_Array;
      Min_Closed  : Boolean;
      Max_Closed  : Boolean;
      Callback    : not null access
        procedure (Index : Marlowe.Database_Index));

private

   type Table_Reference is new Positive;

   type Record_Reference is
      record
         Table : Table_Reference;
         Index : Marlowe.Database_Index;
      end record;

   type Field_Reference is new Natural;

   No_Field : constant Field_Reference := 0;

   type Key_Reference is new Natural;

   No_Key : constant Key_Reference := 0;

end Kit.SQL.Database;
