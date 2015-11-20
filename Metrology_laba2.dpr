program Metrology_laba2;

{$APPTYPE CONSOLE}

uses
  SysUtils,Windows,RegExpr;

var
  RegEx:TRegExpr;
  InputString:string;
  ActualAddressCount,AvaliableAddressCount:integer;
  ArrayStringOfFunctions,ArrayOfGlobalVariables:array of string;
  IsCorrectFileName:boolean;

procedure ReadCodeFromFile();
var
    NewFile:textfile;
    FileName:string;
    Buf:string;
    begin
        FileName:='D:\\AnalyzingCode.txt';
        if FileExists(FileName) then
          begin
            AssignFile(NewFile,FileName);
            Reset(NewFile);
            while Eof(Newfile)<>true do
              begin
                readln(Newfile,Buf);
                InputString:=InputString + Buf + #13#10;
              end;
               CloseFile(NewFile);
               IsCorrectFileName:=true;
          end
        else
            IsCorrectFileName:=false;
    end;

procedure DeleteCommentsFromCode ();
  begin
    RegEx.ModifierS:=false;
    RegEx.Expression:='(\".*\")|(\''.*\'')';
    InputString := RegEx.Replace(InputString,'');
    RegEx.ModifierS:=true;
    RegEx.InputString := InputString;
    RegEx.Expression := '(\/\*).*?(\*\/)';
    InputString := RegEx.Replace(InputString,'');
    RegEx.Expression := '(\/\/).*?\n';
    InputString := RegEx.Replace(InputString,'');
  end;

function FillVariableBySpaces (var SpaceCount:integer):string;
const
  Space = ' ';
var
  IndexSpace:integer;
begin
  Result:='';
  for IndexSpace:=1 to SpaceCount do
    result:=result + Space;
end;

procedure ReplaceString (var WorkString:string; StringPosition,StringLength:integer);
var
  Spaces:string;
begin
  Delete(WorkString,StringPosition,StringLength);
  Spaces:=FillVariableBySpaces(StringLength);
  Insert(Spaces,WorkString,StringPosition);
end;

procedure CopyToFunctionString (var WorkString:string;StringPosition,StringLength:integer);
begin
  SetLength(ArrayStringOfFunctions,length(ArrayStringOfFunctions)+1);
  ArrayStringOfFunctions[length(ArrayStringOfFunctions)-1]:=Copy(WorkString,StringPosition,StringLength);
  ReplaceString(WorkString,StringPosition,StringLength);
end;

procedure FindAndMoveFunctions ();
const
  ArrayTypesIdentifiers:array [1..8] of string = ('(\bchar\b)','(\bbool\b)','(\bshort\b)','(\bint\b)','(\blong\b)','(\bfloat\b)',
                                                    '(\bdouble\b)','(\bvoid\b)');
var
  ArrayElementNumber,BraceCount,FunctionPosition:integer;
begin
  RegEx.ModifierS:=true;
  RegEx.ModifierI:=true;
  for ArrayElementNumber:=1 to length(ArrayTypesIdentifiers) do
    begin
       RegEx.Expression := ArrayTypesIdentifiers[ArrayElementNumber] + '[ ,a-z,0-9,_,\n]*\([^}]*?\{';
       if regex.Exec(Inputstring) then
         repeat
           BraceCount:=1;
           FunctionPosition:=RegEx.MatchPos[0];
           ReplaceString(InputString,RegEx.MatchPos[0],RegEx.MatchLen[1]);
           RegEx.Expression := '[\{\}]';
           if RegEx.ExecPos(FunctionPosition+RegEx.MatchLen[0]) then
            repeat
              if RegEx.Match[0] = '{' then
                inc(BraceCount)
              else if RegEx.Match[0] = '}' then
                dec(BraceCount);
            until (BraceCount = 0) or (not (RegEx.ExecNext));
           CopyToFunctionString(InputString,FunctionPosition,regEx.MatchPos[0]-FunctionPosition+1);
           RegEx.Expression := ArrayTypesIdentifiers[ArrayElementNumber] + '[ ,a-z,0-9,_,\n]*\([^}]*?\{';
         until not (regex.ExecPos(RegEx.MatchPos[0]));
    end;
end;

procedure GlobalVariablesCount ();
const
  ArrayTypesIdentifiers:array [1..8] of string = ('(\bchar\b)','(\bbool\b)','(\bshort\b)','(\bint\b)','(\blong\b)','(\bfloat\b)',
                                                    '(\bdouble\b)','(\bvoid\b)');
var
  ArrayElementNumber,NextPositionSearch:integer;
begin
  for ArrayElementNumber:=1 to length(ArrayTypesIdentifiers) do
    begin
      RegEx.Expression := ArrayTypesIdentifiers[ArrayElementNumber] + '([ ,]*?)([a-z0-9_]+)([ \[\]]*?(\,|\;|\=))';
      if RegEx.Exec(InputString) then
        repeat
          SetLength(ArrayOfGlobalVariables,length(ArrayOfGlobalVariables)+1);
          ArrayOfGlobalVariables[length(ArrayOfGlobalVariables)-1]:=RegEx.Match[3];
          ReplaceString(InputString,RegEx.MatchPos[0]+RegEx.MatchLen[1],RegEx.MatchLen[0]-RegEx.MatchLen[1]-1);
          NextPositionSearch:=RegEx.MatchPos[0];
          RegEx.InputString:=InputString;
        until not RegEx.ExecPos(NextPositionSearch);
    end;
end;

procedure FindAndDeleteLocalVariables ();
const
  ArrayTypesIdentifiers:array [1..8] of string = ('(\bchar\b)','(\bbool\b)','(\bshort\b)','(\bint\b)','(\blong\b)','(\bfloat\b)',
                                                    '(\bdouble\b)','(\bvoid\b)');
var
  ArrayElementNumber,ArrayElementCount,NextPositionSearch:integer;
  VariableName:string;
begin
  for ArrayElementNumber:=0 to length(ArrayStringOfFunctions)-1 do
    begin
      for ArrayElementCount:=1 to length(ArrayTypesIdentifiers) do
        begin
          RegEx.Expression := ArrayTypesIdentifiers[ArrayElementCount] + '([ ,]*?)([a-z0-9_]+)( *?([,;=\[]))';
          if RegEx.Exec(ArrayStringOfFunctions[ArrayElementNumber]) then
            repeat
              //ReplaceString(ArrayStringOfFunctions[ArrayElementNumber],RegEx.MatchPos[0],RegEx.MatchLen[0]);
              ReplaceString(ArrayStringOfFunctions[ArrayElementNumber],RegEx.MatchPos[0]+RegEx.MatchLen[1],RegEx.MatchLen[0]-RegEx.MatchLen[1]-1);
              NextPositionSearch:=RegEx.MatchPos[0]; {+ RegEx.MatchLen[0]};
              VariableName:=RegEx.Match[3];
              RegEx.Expression := '\b' + VariableName + '\b';
              if RegEx.ExecPos(RegEx.MatchPos[0] + RegEx.MatchLen[0]) then
                repeat
                  ReplaceString(ArrayStringOfFunctions[ArrayElementNumber],RegEx.MatchPos[0],RegEx.MatchLen[0]);
                until not (RegEx.ExecNext);

              RegEx.Expression := ArrayTypesIdentifiers[ArrayElementCount] + '([ ,]*?)([a-z0-9_]+)( *?([,;=\[]))';
              RegEx.InputString:=ArrayStringOfFunctions[ArrayElementNumber];
            until not (RegEx.ExecPos(NextPositionSearch));
        end;
    end;
end;

procedure ActualAddressVariablesCount ();
var
  ArrayElementNumber,ArrayElementCount:integer;
begin
  for ArrayElementNumber := 0 to length(ArrayOfGlobalVariables)-1 do
    begin
      RegEx.Expression:='\b' + ArrayOfGlobalVariables[ArrayElementNumber] + '\b';
      for ArrayElementCount:=0 to length(ArrayStringOfFunctions)-1 do
        begin
          if RegEx.Exec(ArrayStringOfFunctions[ArrayElementCount]) then
            inc(ActualAddressCount);
        end;
    end;
end;

begin
  SetConsoleCp(1251);
  SetConsoleOutputCP(1251);
  RegEx := TRegExpr.Create;
  ReadCodeFromFile();
  If IsCorrectFileName = true then
    begin
      DeleteCommentsFromCode();
      FindAndMoveFunctions();
      GlobalVariablesCount();
      FindAndDeleteLocalVariables();
      ActualAddressVariablesCount();
      Writeln('Количество глобальных переменных: ', length(ArrayOfGlobalVariables));
      Writeln('Количество фактических обращений к глобальным переменным: ',ActualAddressCount);
      AvaliableAddressCount:=length(ArrayOfGlobalVariables)*length(ArrayStringOfFunctions);
      Writeln('Количество возможных обращений к глобальным переменным: ', AvaliableAddressCount);
      Writeln('отношение фактических обращений к возмодным: ', (ActualAddressCount/AvaliableAddressCount):0:3);
      Readln;
    end
  else
    begin
      Writeln('File not found!');
      Readln;
    end;
end.
