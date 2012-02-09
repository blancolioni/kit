with Ada.Containers.Hashed_Maps;
with Ada.Unchecked_Deallocation;

with Kit.Mutex;

package body Kit.Cache is

   Max_Table_Index : constant := 256;

   type Cache_Entry_Key is
      record
         Rec     : Marlowe.Table_Index;
         Index   : Marlowe.Database_Index;
      end record;

   function Database_Index_Hash (Key : Cache_Entry_Key)
                                 return Ada.Containers.Hash_Type;

   package Cache_Map is
     new Ada.Containers.Hashed_Maps (Key_Type        => Cache_Entry_Key,
                                     Element_Type    => Cache_Entry,
                                     Hash            => Database_Index_Hash,
                                     Equivalent_Keys => "=");

   Local_Cache : Cache_Map.Map;
   LRU         : List_Of_Cache_Entries.List;

   Max_Cache_Size : Natural := 100_000;
   --  Maximum number of objects in the cache
   --  Should, of course, be settable and tunable.

   procedure Free is
      new Ada.Unchecked_Deallocation (Cache_Entry_Record'Class,
                                      Cache_Entry);

   procedure Update_LRU (Item : not null access Cache_Entry_Record'Class);
   procedure Reference (Item : not null access Cache_Entry_Record'Class);
   procedure Unreference (Item : not null access Cache_Entry_Record'Class);

   function To_Cache_Index (Rec    : Marlowe.Table_Index;
                            Index  : Marlowe.Database_Index)
                           return Marlowe.Database_Index;

   Cache_Mutex : Mutex.Mutex_Type;

   Global_Tick : Tick := 0;
   Tick_Mutex  : Mutex.Mutex_Type;

   Current_Cache_Size : Natural := 0;
   --  The cache size can be larger than the maximum if it's
   --  full of locked entries.

   -----------
   -- Close --
   -----------

   procedure Close is
   begin

      Cache_Mutex.Lock;

      --  Entry_Cache.Close (Local_Cache);

      Cache_Mutex.Unlock;

   end Close;

   -------------------------
   -- Database_Index_Hash --
   -------------------------

   function Database_Index_Hash (Key : Cache_Entry_Key)
                                 return Ada.Containers.Hash_Type
   is
      use type Marlowe.Database_Index;
   begin
      return Ada.Containers.Hash_Type
        (((Key.Index * Marlowe.Database_Index (Max_Table_Index))
          + Marlowe.Database_Index (Key.Rec))
         mod Ada.Containers.Hash_Type'Modulus);
   end Database_Index_Hash;

   ---------------------
   -- Get_Cache_Index --
   ---------------------

   function Get_Cache_Index
     (From : Cache_Entry)
     return Marlowe.Database_Index
   is
   begin
      return To_Cache_Index (From.Rec, From.Index);
   end Get_Cache_Index;

   --------------------------
   -- Get_Cache_Statistics --
   --------------------------

   procedure Get_Cache_Statistics (Blocks :    out Natural;
                                   Pages  :    out Natural;
                                   Hits   :    out Natural;
                                   Misses :    out Natural)
   is
   begin
--        Entry_Cache.Get_Cache_Statistics (Local_Cache,
--                                          Blocks, Pages, Hits, Misses);
      null;
   end Get_Cache_Statistics;

   ---------------
   -- Get_Index --
   ---------------

   function Get_Index       (From : Cache_Entry_Record'Class)
                            return Marlowe.Database_Index
   is
   begin
      return From.Index;
   end Get_Index;

   ---------------------
   -- Get_Table_Reference --
   ---------------------

   function Get_Table_Index
     (From : Cache_Entry_Record'Class)
     return Marlowe.Table_Index
   is
   begin
      return From.Rec;
   end Get_Table_Index;

   -----------
   -- Image --
   -----------

   function Image (L : access Cache_Entry_Record) return String is
   begin
      return Marlowe.Table_Index'Image (L.Rec) &
        Marlowe.Database_Index'Image (L.Index);
   end Image;

   ----------------
   -- Initialise --
   ----------------

   procedure Initialise (Ent   : in out Cache_Entry_Record'Class;
                         Rec   : in     Marlowe.Table_Index;
                         Index : in     Marlowe.Database_Index)
   is
   begin
      Ent.Rec   := Rec;
      Ent.Index := Index;
   end Initialise;

   ------------
   -- Insert --
   ------------

   procedure Insert   (New_Entry : in Cache_Entry) is
   begin

      while Current_Cache_Size >= Max_Cache_Size loop
         declare
            use List_Of_Cache_Entries;
            Item : Cursor := LRU.Last;
            E    : Cache_Entry := Element (Item);
         begin
            exit when E.X_Locked
              or else E.S_Locked
              or else E.Dirty
              or else E.References > 0;
            Local_Cache.Delete ((E.Rec, E.Index));
            LRU.Delete (Item);
            Free (E);
            Current_Cache_Size := Current_Cache_Size - 1;
         end;
      end loop;

      Local_Cache.Insert (Key      => (New_Entry.Rec, New_Entry.Index),
                          New_Item => New_Entry);
      New_Entry.Cached     := True;
      New_Entry.References := 0;
      LRU.Prepend (New_Entry);
      New_Entry.LRU := LRU.First;
      Current_Cache_Size := Current_Cache_Size + 1;

   end Insert;

   ----------------
   -- Lock_Cache --
   ----------------

   procedure Lock_Cache is
   begin
      Cache_Mutex.Lock;
   end Lock_Cache;

   ---------------
   -- Reference --
   ---------------

   procedure Reference (Item : not null access Cache_Entry_Record'Class) is
   begin
      --  Item.References := Item.References + 1;
      Update_LRU (Item);
   end Reference;

   ----------------------
   -- Reset_Statistics --
   ----------------------

   procedure Reset_Statistics is
   begin
      --  Entry_Cache.Reset_Statistics (Local_Cache);
      null;
   end Reset_Statistics;

   --------------
   -- Retrieve --
   --------------

   function  Retrieve (Rec    : Marlowe.Table_Index;
                       Index  : Marlowe.Database_Index)
                      return Cache_Entry
   is
      Result  : Cache_Entry := null;
   begin

      if Local_Cache.Contains ((Rec, Index))  then

         Result := Local_Cache.Element ((Rec, Index));
         Update_LRU (Result);

      end if;
      return Result;
--
--
--
--        Entry_Cache.Fetch (Local_Cache, To_Cache_Index (Rec, Index),
--                           Success, Result, Handle);
--        if Result /= null then
--           Result.Handle := Handle;
--           Result.Cached := True;
--        end if;
--
--        return Result;
   end Retrieve;

   ------------
   -- S_Lock --
   ------------

   overriding
   procedure S_Lock (Item : not null access Cache_Entry_Record) is
   begin
      Locking.Root_Lockable_Type (Item.all).S_Lock;
      Item.Reference;

      Tick_Mutex.Lock;
      Item.Last_Access := Global_Tick;
      Global_Tick   := Global_Tick + 1;
      Tick_Mutex.Unlock;

   end S_Lock;

   ------------------------
   -- Set_Max_Cache_Size --
   ------------------------

   procedure Set_Max_Cache_Size (Size : Natural) is
   begin
      Max_Cache_Size := Size;
   end Set_Max_Cache_Size;

   -----------------
   -- Start_Cache --
   -----------------

   procedure Start_Cache is
   begin
      --  Entry_Cache.Enable_Debug (True);
      --  Local_Cache := Entry_Cache.Create_Cache (Max_Cache_Size);
      null;
   end Start_Cache;

   --------------------
   -- To_Cache_Index --
   --------------------

   function To_Cache_Index (Rec    : Marlowe.Table_Index;
                            Index  : Marlowe.Database_Index)
                           return Marlowe.Database_Index
   is
      use type Marlowe.Database_Index;
   begin
      return Index * Max_Table_Index
        + Marlowe.Database_Index (Rec);
   end To_Cache_Index;

   ------------
   -- Unlock --
   ------------

   overriding
   ------------
   -- Unlock --
   ------------

   procedure Unlock (Item : not null access Cache_Entry_Record) is
   begin
      if Item.X_Locked then
         Item.Dirty := False;
         Cache_Entry_Record'Class (Item.all).Write (Item.Index);
      end if;

      Locking.Root_Lockable_Type (Item.all).Unlock;

      Item.Unreference;

   end Unlock;

   ------------------
   -- Unlock_Cache --
   ------------------

   procedure Unlock_Cache is
   begin
      Cache_Mutex.Unlock;
   end Unlock_Cache;

   -----------------
   -- Unreference --
   -----------------

   procedure Unreference (Item : not null access Cache_Entry_Record'Class) is
   begin
      Update_LRU (Item);
      --  Item.References := Item.References - 1;
   end Unreference;

   ----------------
   -- Update_LRU --
   ----------------

   procedure Update_LRU (Item : not null access Cache_Entry_Record'Class) is
   begin
      if Item.Cached then
         LRU.Delete (Item.LRU);
         LRU.Prepend (Cache_Entry (Item));
         Item.LRU := LRU.First;
      end if;
   end Update_LRU;

   ------------
   -- X_Lock --
   ------------

   overriding
   procedure X_Lock (Item : not null access Cache_Entry_Record) is
   begin
      Locking.Root_Lockable_Type (Item.all).X_Lock;
      Item.Dirty := True;
      Item.Reference;

      Tick_Mutex.Lock;
      Item.Last_Access := Global_Tick;
      Global_Tick   := Global_Tick + 1;
      Tick_Mutex.Unlock;

   end X_Lock;

end Kit.Cache;
