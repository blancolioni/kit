package Kit.Notifier is

   type Table_Notify_Interface is interface;

   procedure Notify_Table_Change
     (Handle : Table_Notify_Interface)
   is null;

   type Record_Notify_Interface is interface;

   procedure Notify_Record_Change
     (Handle         : Record_Notify_Interface;
      Changed_Record : Marlowe.Database_Index)
   is null;

   procedure Add_Table_Change_Handler
     (Table   : Marlowe.Table_Index;
      Handler : Table_Notify_Interface'Class);

   procedure Add_Delete_Record_Handler
     (Table   : Marlowe.Table_Index;
      Handler : Record_Notify_Interface'Class);

   procedure Add_New_Record_Handler
     (Table   : Marlowe.Table_Index;
      Handler : Record_Notify_Interface'Class);

   procedure Add_Record_Change_Handler
     (Table   : Marlowe.Table_Index;
      Index   : Marlowe.Database_Index;
      Handler : Record_Notify_Interface'Class);

   procedure Table_Changed
     (Table   : Marlowe.Table_Index);

   procedure Record_Changed
     (Table   : Marlowe.Table_Index;
      Index   : Marlowe.Database_Index);

end Kit.Notifier;
