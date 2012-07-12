package body Kit.Schema.Fields is


   --------------
   -- Ada_Name --
   --------------

   function Ada_Name (Item  : Compound_Field_Type;
                      Index : Positive)
                      return String
   is
   begin
      return Item.Fields.Element (Index).Ada_Name;
   end Ada_Name;

   ---------------
   -- Add_Field --
   ---------------

   procedure Add_Field (Item  : in out Compound_Field_Type;
                        Field : not null access Field_Type'Class)
   is
   begin
      Item.Fields.Append (Field_Access (Field));
      Item.Size := Item.Size + Field.Size;
   end Add_Field;

   --------------
   -- Contains --
   --------------

   function Contains (Item  : Compound_Field_Type;
                      Field : Field_Type'Class)
                      return Boolean
   is
   begin
      for F of Item.Fields loop
         if F.Ada_Name = Field.Ada_Name then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   ------------------
   -- Create_Field --
   ------------------

   procedure Create_Field (Item       : in out Field_Type;
                           Name       : in     String;
                           Field_Type : in     Kit.Schema.Types.Kit_Type'Class)
   is
   begin
      Item.Create (Name);
      Item.Field_Type :=
        new Kit.Schema.Types.Kit_Type'Class'(Field_Type);
      Item.Size := Item.Field_Type.Size;
   end Create_Field;

   ------------------
   -- Create_Field --
   ------------------

   procedure Create_Field (Item       : in out Compound_Field_Type;
                           Name       : in     String)
   is
   begin
      Item.Create (Name);
      Item.Size := 0;
      Item.Created := False;
      Item.Readable := False;
      Item.Writeable := False;
   end Create_Field;

   -------------
   -- Created --
   -------------

   function Created (Field : Field_Type) return Boolean is
   begin
      return Field.Created;
   end Created;

   ------------------
   -- Equal_Fields --
   ------------------

   function Equal_Fields (Left, Right : Field_Access) return Boolean is
   begin
      return Left.Ada_Name = Right.Ada_Name;
   end Equal_Fields;

   -----------
   -- Field --
   -----------

   function Field (Item : Compound_Field_Type;
                   Index : Positive)
                   return Field_Type'Class
   is
   begin
      return Field_Type'Class (Item.Fields.Element (Index).all);
   end Field;

   -----------------
   -- Field_Count --
   -----------------

   function Field_Count (Item : Compound_Field_Type) return Natural is
   begin
      return Item.Fields.Last_Index;
   end Field_Count;

   --------------------
   -- Get_Field_Type --
   --------------------

   function Get_Field_Type (Item : Field_Type)
                           return Kit.Schema.Types.Kit_Type'Class
   is
   begin
      return Item.Field_Type.all;
   end Get_Field_Type;

   --------------
   -- Readable --
   --------------

   function Readable (Field : Field_Type) return Boolean is
   begin
      return Field.Readable;
   end Readable;

   -----------------------
   -- Set_Field_Options --
   -----------------------

   procedure Set_Field_Options
     (Field    : in out Root_Field_Type'Class;
      Created  : Boolean := False;
      Readable : Boolean := False;
      Writable : Boolean := False)
   is
   begin
      Field.Created := Created;
      Field.Readable := Readable;
      Field.Writeable := Writable;
   end Set_Field_Options;

   ----------
   -- Size --
   ----------

   function Size (Item : Root_Field_Type) return Natural is
   begin
      return Item.Size;
   end Size;

   ---------------
   -- Writeable --
   ---------------

   function Writeable (Field : Field_Type) return Boolean is
   begin
      return Field.Writeable;
   end Writeable;

end Kit.Schema.Fields;
