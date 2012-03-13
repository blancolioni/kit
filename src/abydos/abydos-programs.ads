with Abydos.Environments;
with Abydos.Statements;
with Abydos.Values;

package Abydos.Programs is

   type Program is private;

   procedure Update_Program (Name       : String;
                             Arguments  : Abydos.Values.Array_Of_Values;
                             Definition : Abydos.Statements.Statement);

   function Execute (Name        : String;
                     Arguments   : Values.Array_Of_Values;
                     Environment : Environments.Environment)
                    return Values.Value;

private

   type Program_Record;
   type Program is access Program_Record;

end Abydos.Programs;
