unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, VListBox, Types, LazFileUtils, TAGraph,
  VChartControl, vtypes;


type

  { TForm1 }

  TForm1 = class(TForm)
    ButtonZoomIn: TButton;
    ButtonCloseAll2: TButton;
    ButtonFontSize: TButton;
    CBAllowDrag: TCheckBox;
    CBLeftAxis: TCheckBox;
    CBBottomAxis: TCheckBox;
    CBAllowZoom: TCheckBox;
    ColorButton1: TColorButton;
    ImageList2: TImageList;
    LabelStatus: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter2: TSplitter;
    Timer1: TTimer;
    VChartControl1: TVChartControl;
    VListBox1: TVListBox;
    procedure ButtonFontSizeClick(Sender: TObject);
    procedure ButtonZoomInClick(Sender: TObject);
    procedure ButtonCloseAll2Click(Sender: TObject);
    procedure CBAllowDragChange(Sender: TObject);
    procedure CBBottomAxisChange(Sender: TObject);
    procedure CBAllowZoomChange(Sender: TObject);
    procedure CBLeftAxisChange(Sender: TObject);
    procedure ColorButton1ColorChanged(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure VChartControl1ChartDraw(Sender: TObject; C: TCanvas;
      const AxisRect, ImageRect: TRect);
    procedure VChartControl1CursorAMove(Sender: TObject);
    procedure VChartControl1CursorBMove(Sender: TObject);
    procedure VChartControl1CursorsDraw(Sender: TObject; ACanvas: TCanvas;
      ImageRect: TRect; aX, bX: integer);
    procedure VChartControl1GetDragPoint(Sender: TObject; X, Y: integer;
      var N: integer);
    procedure VChartControl1MovePoint(Sender: TObject; Y: integer; N: integer);
    procedure VChartControl1ZoomRectDraw(Sender: TObject; ACanvas: TCanvas;
      ImageRect, ZoomRect: TRect);
    procedure VListBox1DblClick(Sender: TObject);
    procedure VListBox1DrawItem(Sender: TObject; C: TCanvas; AIndex: integer;
      const ARect: TRect);
    procedure VListBox1Selection(Sender: TObject);
  private
    SL: TStringList;
    arp: array of TPoint;
    da: array of double;
    aTextHeight, aTextHeight2: integer;
    procedure ShowCursorInfo;
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
const
  Padding = 3;

implementation

uses FileUtil,  math, LCLIntf;

const
  GrabRadius = 4;

{$R *.lfm}

{ TForm1 }

procedure TForm1.VListBox1DrawItem(Sender: TObject; C: TCanvas;
  AIndex: integer; const ARect: TRect);
var
  X, Y, n: integer;
begin
  if AIndex>2 then n:=1 else n:=0;
  case AIndex of
  0, 2: n:=0;
  1: n:=1;
  3, 4: n:= 2;
  else n:=-1;
  end;
  if (n>=0) and (n<ImageList2.Count) then
  begin
    X:= ARect.Left+Padding;
    Y:= ARect.Top+ (ARect.Height - ImageList2.Height) div 2;
    ImageList2.Draw(C, X, Y, n);
    X:= X + ImageList2.Width;
    if AIndex=2 then
    begin
      ImageList2.Draw(C, X+1, Y, 1);
      X:=X+ ImageList2.Width+1;
    end;
  end;
  C.TextOut(X+ Padding, ARect.Top+ (ARect.Height - aTextHeight) div 2, SL[AIndex]);
end;

procedure TForm1.VListBox1Selection(Sender: TObject);
begin
  case VListBox1.ItemIndex of
    0, 1, 2:
       begin
         Timer1.Enabled:=false;
         CBBottomAxis.Checked:=true;
         CBLeftAxis.Checked:=true;
       end;
    3: begin
         Timer1.Enabled:=false;
         Timer1.Tag:=High(da);
         CBBottomAxis.Checked:=false;
         CBLeftAxis.Checked:=false;
       end;
    4: begin
         Timer1.Tag:=2;
         Timer1.Enabled:=true;
         CBBottomAxis.Checked:=false;
         CBLeftAxis.Checked:=false;
       end;
    5: begin

       end;
    6: begin

       end;
    else ;
  end;
  VChartControl1.DragMode:= CBAllowDrag.Checked and (VListBox1.ItemIndex=3);
  if VListBox1.ItemIndex>=0 then LabelStatus.Caption:= SL[VListBox1.ItemIndex];
  VChartControl1.RenderChart;
end;

procedure TForm1.ButtonZoomInClick(Sender: TObject);
var
  dr: TDoubleRect;
begin
  dr:= VChartControl1.ZoomExtent;
  dr.Inflate(-dr.Width/10, -dr.Height/10);
  VChartControl1.ZoomExtent:=dr;
end;

procedure TForm1.ButtonFontSizeClick(Sender: TObject);
var
  ts: integer;
begin
  ts:= max(VListBox1.Font.Size, 9) +1;
  VListBox1.Font.Size:=ts;
  aTextHeight:=VListBox1.Canvas.TextHeight('Qq');
  aTextHeight2:=aTextHeight div 2;
  VListBox1.ItemHeight:=max(2*aTextHeight, ImageList2.Height) + 3*Padding; //repaint
  VChartControl1.Font.Size:= ts;
  VChartControl1.RenderChart;
end;

procedure TForm1.ButtonCloseAll2Click(Sender: TObject);
begin
  VChartControl1.CancelZoom;
end;

procedure TForm1.CBAllowDragChange(Sender: TObject);
begin
  VChartControl1.DragMode:= CBAllowDrag.Checked and (VListBox1.ItemIndex=3);
end;

procedure TForm1.CBBottomAxisChange(Sender: TObject);
begin
  if CBBottomAxis.Checked then VChartControl1.BottomAxisHeight:=32
  else VChartControl1.BottomAxisHeight:=0;
end;

procedure TForm1.CBAllowZoomChange(Sender: TObject);
begin
  VChartControl1.AllowZoom:=CBAllowZoom.Checked;
end;

procedure TForm1.CBLeftAxisChange(Sender: TObject);
begin
  if CBLeftAxis.Checked then VChartControl1.LeftAxisWidth:=48
  else VChartControl1.LeftAxisWidth:=0;
end;

procedure TForm1.ColorButton1ColorChanged(Sender: TObject);
begin
  VChartControl1.Color:=ColorButton1.ButtonColor;
  VChartControl1.RenderChart;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  SL:= TStringList.Create;
  VChartControl1.Extent:=TDoubleRect.Create(-2*pi, 2, 3*pi, -2);
  SetLength(da, 50);
  for i:=0 to high(da) do da[i]:= (250-Random(500))/150;
  SL.Add('Sin(x)');
  SL.Add('Cos(x)');
  SL.Add('Sin(x) & Cos(x)');
  SL.Add('Line chart');
  SL.Add('Dynamic line chart');
  VListBox1Selection(Sender);
  VListBox1.ItemCount:=SL.Count;
  aTextHeight:=VListBox1.Canvas.TextHeight('Qq');
  aTextHeight2:=aTextHeight div 2;
  VListBox1.ItemHeight:=max(2*aTextHeight, ImageList2.Height) + 3*Padding;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  SL.Free;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  i: integer;
begin
  Timer1.Tag:=Timer1.Tag+1;
  if Timer1.Tag>1000 then Timer1.Tag:=2
  else if Timer1.Tag>high(da) then
  begin
    for i:=1 to high(da) do da[i-1]:=da[i];
    da[high(da)]:= (200-Random(400))/150;
  end;
  VChartControl1.RenderChart;
end;

procedure TForm1.VChartControl1ChartDraw(Sender: TObject; C: TCanvas;
  const AxisRect, ImageRect: TRect);

var
  dx, xx: double;
  X, Y: integer;
  n: integer;

const pxl = 6;

procedure DrawSin;
var
  i: integer;
begin
  C.Pen.Color:=clBlue;
  n:= 2+ ImageRect.Width div pxl;
  SetLength(arp, n);
  X:=ImageRect.Left-1;
  for i:=0 to n-1 do
  begin
    xx:=VChartControl1.ImageToGraphX(X);
    arp[i].x:=X;
    arp[i].y:=VChartControl1.GraphToImageY(sin(xx));
    X+=pxl;
  end;
  C.Polyline(arp);
end;

procedure DrawCos;
var
  i: integer;
begin
  C.Pen.Color:=clGreen;
  n:= 2+ImageRect.Width div pxl;
  SetLength(arp, n);
  X:=ImageRect.Left-1;
  for i:=0 to n-1 do
  begin
    xx:=VChartControl1.ImageToGraphX(X);
    arp[i].x:=X;
    arp[i].y:=VChartControl1.GraphToImageY(cos(xx));
    X+=pxl;
  end;
  C.Polyline(arp);
end;

procedure RandomLine;
var
  i, k, k2: integer;
begin
  C.Pen.Color:=clTeal;
  n:=Length(da)-1;
  dx:=VChartControl1.Extent.Width/n;
  k:= trunc((VChartControl1.ZoomExtent.Left - VChartControl1.Extent.Left)/dx);
  k2:=min(min(n, Timer1.Tag), 1+ trunc((VChartControl1.ZoomExtent.Right - VChartControl1.Extent.Left)/dx));
  n:=k2-k+1;
  if n>1 then
  begin
    SetLength(arp, n);
    xx:= VChartControl1.Extent.Left+ dx*k;
    for i:= 0 to n-1 do
    begin
      arp[i]:=VChartControl1.GraphToImage(xx, da[i+k]);
      xx+= dx;
    end;
    C.Polyline(arp);
    if (VListBox1.ItemIndex=3) and VChartControl1.DragMode then
    begin
      C.Brush.Color:=C.Pen.Color;
      for i:= 0 to n-1 do C.Rectangle(arp[i].x-GrabRadius,arp[i].y-GrabRadius, arp[i].x+succ(GrabRadius), arp[i].y+succ(GrabRadius));
    end;
  end;
end;

function CalcGridStep(aRange: double; cnt: integer) : double;
var
  d: double;
  k: integer;
begin
  if cnt<1 then exit(aRange);
  d:= intpower(10, Floor(log10(aRange/cnt)));
  k:=trunc(aRange/cnt/d);
  if k<2 then exit(d);
  if k<4 then exit(d+d);
  if k<7 then k:=5 else k:=10;
  Result:=k*d;
end;

function GetDigits(d: double): integer;
begin
  Result:= max(0, -floor(log10(d)));
end;

procedure DrawAxis;
var
  X1, Y1: integer;
  koeff, yy, dy: double;
  aGridBounds, aTickBounds: TRect;
  s: string;
  wt, ht, digits: integer;
begin
  ht:= C.TextHeight('1') div 2;
  Y:=ImageRect.Bottom;
  X:=ImageRect.Left;
  if VChartControl1.BottomAxisHeight>0 then Y+=1;
  if VChartControl1.LeftAxisWidth>0 then X-=1;

  aGridBounds:=ImageRect;
  aGridBounds.Inflate(-ScaleX(4, 96), -ScaleY(4, 96), -ScaleX(5, 96), -ScaleY(4, 96));

  aTickBounds:=ImageRect;
  aTickBounds.Inflate(0, -aTextHeight- aTextHeight2, -ScaleX(30, 96), - aTextHeight2);

  //Left axis

  n:= round(0.9 + ImageRect.Height/ScaleX(150, 96));   //+trunc(sqrt(ImageRect.Height))
  if n>0 then
  begin
    dy:= CalcGridStep(VChartControl1.ZoomExtent.Height, n);
    dy:=max(dy, 0.001);
    digits:=GetDigits(dy);
    yy:= ceil(VChartControl1.ZoomExtent.Top/dy)*dy;
    while yy< VChartControl1.ZoomExtent.Bottom do
    begin
      Y1:= VChartControl1.GraphToImageY(yy);

      if InRange(Y1, aGridBounds.Top, aGridBounds.Bottom) then
      begin
        C.Pen.Color:=clSilver;
        C.Line(ImageRect.Left, Y1, ImageRect.Right, Y1);
      end;

      if (VChartControl1.LeftAxisWidth>0) and InRange(Y1, ImageRect.Top + aTextHeight+ aTextHeight2, ImageRect.Bottom - aTextHeight2) then
      begin
        C.Pen.Color:=clBlack;
        C.Line(ImageRect.Left-6, Y1, ImageRect.Left, Y1);

        s:=FloatToStrF(yy, ffNumber, 2, digits);
        wt:=C.TextWidth(s);

        C.TextOut(ImageRect.Left-6 - wt - 3, Y1-ht, s);
      end;

      yy:=yy+dy;
    end;
  end;

  if VChartControl1.LeftAxisWidth>0 then
  begin
    C.Pen.Color:=clBlack;
    C.Line(ImageRect.Left-1, ImageRect.Top, ImageRect.Left-1, ImageRect.Bottom+1);
  end;

  //Bottom axis
  koeff:=pi;
  n:= round(0.9 + ImageRect.Width/ScaleX(150 + trunc(sqrt(ImageRect.Width)), 96));
  if n>0 then
  begin
    dx:= CalcGridStep(VChartControl1.ZoomExtent.Width/koeff, n);
    dx:=max(dx, 0.001);
    digits:=GetDigits(dx);
    xx:= ceil(VChartControl1.ZoomExtent.Left/koeff/dx)*dx;
    yy:= VChartControl1.ZoomExtent.Right/pi;
    while xx< yy  do
    begin
      X1:= VChartControl1.GraphToImageX(xx*koeff);
      if InRange(X1, aGridBounds.Left, aGridBounds.Right) then
      begin
        C.Pen.Color:=clSilver;
        C.Line(X1, ImageRect.Top, X1, ImageRect.Bottom);
      end;
      if (VChartControl1.BottomAxisHeight>0) and InRange(X1, aTickBounds.Left, aTickBounds.Right) then
      begin
        C.Pen.Color:=clBlack;
        C.Line(X1, Y, X1, Y+6);
        s:=FloatToStrF(xx, ffNumber, 2, digits);
        wt:=C.TextWidth(s) div 2;
        C.TextOut(X1-wt, Y+6, s);
      end;
      xx:=xx+dx;
    end;
  end;
  if VChartControl1.BottomAxisHeight>0 then
  begin
    C.Pen.Color:=clBlack;
    C.Line(ImageRect.Left-1, ImageRect.Bottom, ImageRect.Right, ImageRect.Bottom);
  end;

end;

begin
  DrawAxis;
  C.ClipRect:=ImageRect;
  C.Clipping:=true;
  case VListBox1.ItemIndex of
  0: DrawSin;
  1: DrawCos;
  2: begin
       DrawSin;
       DrawCos;
     end;
  3, 4: RandomLine;
  end;
  if VListBox1.ItemIndex>=0 then
  begin
    C.Brush.Style:=bsClear;
    C.TextOut(ImageRect.Left, ImageRect.Top, SL[VListBox1.ItemIndex]);
  end;
  C.Clipping:=false;
end;

procedure TForm1.ShowCursorInfo;
var
  s: string;
begin
  if VChartControl1.CursorA>DefCursorMin then s:= 'Cursor A: '+ FloatToStrF(VChartControl1.CursorA/pi, ffNumber, 2, 2)+'pi';
  s:=s+'  ';
  if VChartControl1.CursorB>DefCursorMin then s:= s+ 'Cursor B: ' + FloatToStrF(VChartControl1.CursorB/pi, ffNumber, 2, 2)+'pi';
  LabelStatus.Caption:=s;
end;

procedure TForm1.VChartControl1CursorAMove(Sender: TObject);
begin
  ShowCursorInfo;
end;

procedure TForm1.VChartControl1CursorBMove(Sender: TObject);
begin
  ShowCursorInfo;
end;

procedure TForm1.VChartControl1CursorsDraw(Sender: TObject; ACanvas: TCanvas;
  ImageRect: TRect; aX, bX: integer);
begin
  aCanvas.Pen.Width:=1;
  aCanvas.Pen.Mode:=pmNotXor;
  if InRange(aX, ImageRect.Left, ImageRect.Right) then
  begin
    aCanvas.Pen.Color:=clRed;
    aCanvas.Line(aX, ImageRect.Top, aX, ImageRect.Bottom);
  end;
  if InRange(bX, ImageRect.Left, ImageRect.Right) then
  begin
    aCanvas.Pen.Color:=clBlue;
    aCanvas.Line(bX, ImageRect.Top, bX, ImageRect.Bottom);
  end;
  ACanvas.Pen.Mode:=pmCopy;
end;

procedure TForm1.VChartControl1GetDragPoint(Sender: TObject; X, Y: integer;
  var N: integer);
var
  i: integer;
  ie: boolean;
  dx, dy, x0, y0: integer;
begin
  x0:=GrabRadius+1;
  y0:=x0;
  ie:= false;
  N:=-1;
  for i:=0 to High(arp) do
  begin
    dx:=abs(arp[i].x-X);
    dy:=abs(arp[i].y-Y);
    if (dx<x0) and (dy<y0) then
    begin
      x0:=dx;
      y0:=dy;
      ie:=true;
      N:=i;
    end
    else if ie then break;
  end;
end;

procedure TForm1.VChartControl1MovePoint(Sender: TObject; Y: integer; N: integer
  );
var
  n0, k: integer;
  yy: double;
begin
  n0:=Length(da)-1;
  k:= trunc(n0*(VChartControl1.ZoomExtent.Left - VChartControl1.Extent.Left)/VChartControl1.Extent.Width);
  yy:= da[N+k] + VChartControl1.ImageToGraphY(Y) - VChartControl1.ImageToGraphY(arp[N].y);
  if InRange(yy, VChartControl1.ZoomExtent.Top, VChartControl1.ZoomExtent.Bottom) then
  begin
    da[N+k]:=yy;
    VChartControl1.RenderChart;
  end;
end;

procedure TForm1.VChartControl1ZoomRectDraw(Sender: TObject; ACanvas: TCanvas;
  ImageRect, ZoomRect: TRect);
begin
  ACanvas.Pen.Color:=clWindowFrame;
  ACanvas.Pen.Width:=1;
  ACanvas.Frame(ZoomRect);
end;

procedure TForm1.VListBox1DblClick(Sender: TObject);
begin
//
end;



end.

