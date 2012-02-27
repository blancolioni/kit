package Kit.Strings is

   type String_Type (Max_Length : Natural) is
      record
         Text     : String (1 .. Max_Length);
         Length   : Natural := 0;
      end record;

end Kit.Strings;
