with Ada.Characters.Handling;

package body Kit.Names is

   --------------
   -- Ada_Name --
   --------------

   function Ada_Name (Item : Root_Named_Object) return String is
      use Ada.Characters.Handling;
      Result : String := Name (Root_Named_Object'Class (Item));
      Capital : Boolean := True;
   begin
      for I in Result'Range loop
         if Capital then
            Result (I) := To_Upper (Result (I));
            Capital := False;
         elsif Result (I) = '_'
           or else Result (I) = '.'
         then
            Capital := True;
         end if;
      end loop;
      return Result;
   end Ada_Name;

   ------------
   -- Create --
   ------------

   procedure Create
     (Item : in out Root_Named_Object;
      Name : String)
   is
   begin
      Item.Name := Ada.Strings.Unbounded.To_Unbounded_String (Name);
   end Create;

   ----------
   -- Name --
   ----------

   function Name (Item : Root_Named_Object) return String is
   begin
      return Ada.Strings.Unbounded.To_String (Item.Name);
   end Name;

end Kit.Names;
