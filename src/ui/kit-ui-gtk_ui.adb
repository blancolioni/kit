with Ada.Containers.Vectors;
with Ada.Text_IO;

with Glib.Error;

with Gdk.Pixbuf;

with Gtk.Builder;
with Gtk.Handlers;
with Gtk.Label;
with Gtk.Main;
with Gtk.Notebook;
with Gtk.Scrolled_Window;
with Gtk.Tree_View;
with Gtk.Widget;
with Gtk.Window;

with Kit.Db.Database;
with Kit.Paths;

with Kit.UI.Gtk_UI.Table_Book;
with Kit.UI.Gtk_UI.Table_Lists;

package body Kit.UI.Gtk_UI is

   package Window_Callback is
      new Gtk.Handlers.Callback (Gtk.Window.Gtk_Window_Record);

   procedure Destroy_Handler (W : access Gtk.Window.Gtk_Window_Record'Class);

   type Table_Display_Record is
      record
         Name   : access String;
         Widget : Gtk.Widget.Gtk_Widget;
      end record;

   package List_Of_Table_Displays is
     new Ada.Containers.Vectors (Positive, Table_Display_Record);

   type Root_Gtk_UI is
     new Root_Kit_UI
   with
      record
         Top_Level      : Gtk.Window.Gtk_Window;
         Table_List     : Gtk.Tree_View.Gtk_Tree_View;
         Table_Book     : Gtk.Notebook.Gtk_Notebook;
         Table_Displays : access List_Of_Table_Displays.Vector;
      end record;

   function Choose_Database
     (With_UI : Root_Gtk_UI)
      return String;

   procedure Show_Table
     (With_UI    : Root_Gtk_UI;
      Table_Name : String);

   procedure Start (UI   : Root_Gtk_UI;
                    Path : String);

   ---------------------
   -- Choose_Database --
   ---------------------

   function Choose_Database
     (With_UI : Root_Gtk_UI)
      return String
   is
      pragma Unreferenced (With_UI);
   begin
      return "";
   end Choose_Database;

   ---------------------
   -- Destroy_Handler --
   ---------------------

   procedure Destroy_Handler
     (W : access Gtk.Window.Gtk_Window_Record'Class)
   is
      pragma Unreferenced (W);
   begin
      Kit.Db.Database.Close;
      Gtk.Main.Main_Quit;
   end Destroy_Handler;

   ----------------
   -- New_Gtk_UI --
   ----------------

   function New_Gtk_UI return Kit_UI is
      Result : Root_Gtk_UI;
      Builder : Gtk.Builder.Gtk_Builder;
   begin
      Gtk.Main.Init;
      Gtk.Builder.Gtk_New (Builder);

      declare
         use type Glib.Error.GError;
         Path  : constant String :=
                   Kit.Paths.Config_Path & "/ui.glade";
         Error : constant Glib.Error.GError :=
                   Builder.Add_From_File
                     (Filename => Path);
      begin
         if Error /= null then
            raise Program_Error with
              "Error opening GUI definition: " & Path;
         end if;
      end;

      declare
         Main_Window : constant Gtk.Window.Gtk_Window :=
                         Gtk.Window.Gtk_Window
                           (Builder.Get_Object
                              ("Kit_Main"));
         Pixbuf      : Gdk.Pixbuf.Gdk_Pixbuf;
         Error       : Glib.Error.GError;
      begin

         Gdk.Pixbuf.Gdk_New_From_File
           (Pixbuf,
            Kit.Paths.Config_Path & "/kit.png",
            Error);
         Main_Window.Set_Icon (Pixbuf);
         Result.Top_Level := Main_Window;
         Window_Callback.Connect
           (Main_Window,
            "destroy",
            Window_Callback.To_Marshaller (Destroy_Handler'Access));
      end;

      Result.Table_List :=
        Gtk.Tree_View.Gtk_Tree_View
          (Builder.Get_Object ("Table_List"));

      Result.Table_Book :=
        Gtk.Notebook.Gtk_Notebook
          (Builder.Get_Object ("Table_Book"));

      Result.Table_Displays := new List_Of_Table_Displays.Vector;

      return new Root_Gtk_UI'(Result);
   end New_Gtk_UI;

   ----------------
   -- Show_Table --
   ----------------

   procedure Show_Table
     (With_UI    : Root_Gtk_UI;
      Table_Name : String)
   is
   begin
      Ada.Text_IO.Put_Line ("Table: " & Table_Name);
      for I in 1 .. With_UI.Table_Displays.Last_Index loop
         if With_UI.Table_Displays.Element (I).Name.all = Table_Name then
            With_UI.Table_Book.Set_Current_Page (Glib.Gint (I - 1));
            return;
         end if;
      end loop;

      declare
         Scrolled : Gtk.Scrolled_Window.Gtk_Scrolled_Window;
         Widget : constant Gtk.Widget.Gtk_Widget :=
                    Kit.UI.Gtk_UI.Table_Book.New_Table_Display
                      (Table_Name);
         Label  : Gtk.Label.Gtk_Label;
      begin
         Gtk.Scrolled_Window.Gtk_New
           (Scrolled);
         Scrolled.Add (Widget);
         Scrolled.Show_All;
         Gtk.Label.Gtk_New (Label, Table_Name);
         Label.Show_All;
         With_UI.Table_Book.Append_Page (Scrolled, Label);
         With_UI.Table_Displays.Append
           ((new String'(Table_Name), Widget));
         With_UI.Table_Book.Set_Current_Page;
      end;

   end Show_Table;

   -----------
   -- Start --
   -----------

   procedure Start (UI   : Root_Gtk_UI;
                    Path : String)
   is
   begin
      UI.Top_Level.Show_All;
      Kit.Db.Database.Open (Path);
      Kit.UI.Gtk_UI.Table_Lists.Fill_Table_List
        (UI'Unchecked_Access, UI.Table_List);

      Gtk.Main.Main;
   end Start;

end Kit.UI.Gtk_UI;
