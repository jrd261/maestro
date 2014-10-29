function untitled(SignalFileNames,NoiseFileNames)
clear all


data.config.Color_One = [.4 .4 .9];
data.config.Color_Two = [.9 .4 .4];

data.config.TopHeight = 40;
data.config.MiddleHeight = 400;
data.config.BottomHeight = 40;

data.config.TopLeftWidth = 100;
data.config.TopMiddleWidth = 600;
data.config.TopRightWidth = 100;

data.config.BottomLeftWidth = 100;
data.config.BottomMiddleWidth = 600;
data.config.BottomRightWidth = 100;

data.config.ArrowButtonWidth = 50;
data.config.ArrowButtonHeight = 25;
data.config.SelectButtonHeight = 25;
data.config.SelectButtonWidth = 65;

Color_One = data.config.Color_One;
Color_Two = data.config.Color_Two;

data.config.TextPadding = 4;


SelectButtonWidth = data.config.SelectButtonWidth;
SelectButtonHeight = data.config.SelectButtonHeight;

TopMiddleWidth = data.config.TopMiddleWidth;
TopLeftWidth = data.config.TopLeftWidth;
TopRightWidth = data.config.TopRightWidth;
FullWidth = TopLeftWidth + TopMiddleWidth + TopRightWidth;

BottomLeftWidth = data.config.BottomLeftWidth;
BottomMiddleWidth = data.config.BottomMiddleWidth;
BottomRightWidth = data.config.BottomRightWidth;

TopHeight = data.config.TopHeight;
BottomHeight = data.config.BottomHeight;
MiddleHeight = data.config.MiddleHeight;

FullHeight = TopHeight+MiddleHeight+BottomHeight;

ArrowButtonHeight = data.config.ArrowButtonHeight;
ArrowButtonWidth = data.config.ArrowButtonWidth;

Padding = (BottomHeight-ArrowButtonHeight)/2;

data.handles.H_Figure = figure('Position',[100,100,FullWidth,FullHeight]);

data.handles.H_Panel_Bottom = uipanel('Parent',data.handles.H_Figure,'Units','pixels','Position',[1 1 FullWidth BottomHeight],'Background',[.9,.9,.9],'BorderType','none');
data.handles.H_Panel_Middle = uipanel('Parent',data.handles.H_Figure,'Units','pixels','Position',[1 1+BottomHeight FullWidth MiddleHeight],'Background',[1,1,1]);
data.handles.H_Panel_Top = uipanel('Parent',data.handles.H_Figure,'Units','pixels','Position',[1 1+BottomHeight+MiddleHeight FullWidth TopHeight],'Background',[.9,.9,.9],'BorderType','none');

data.handles.H_Panel_Top_Right = uipanel('Parent',data.handles.H_Panel_Top,'Units','pixels','Position',[1+TopLeftWidth+TopMiddleWidth 1 TopRightWidth TopHeight],'Background',[1,1,1]);
data.handles.H_Panel_Top_Middle = uipanel('Parent',data.handles.H_Panel_Top,'Units','pixels','Position',[1+TopLeftWidth 1 TopMiddleWidth TopHeight],'Background',[1,1,1]);
data.handles.H_Panel_Top_Left = uipanel('Parent',data.handles.H_Panel_Top,'Units','pixels','Position',[1 1 TopLeftWidth TopHeight],'Background',[1,1,1]);

data.handles.H_Panel_Bottom_Right = uipanel('Parent',data.handles.H_Panel_Bottom,'Units','pixels','Position',[1+BottomLeftWidth+BottomMiddleWidth 1 BottomRightWidth BottomHeight],'Background',[1,1,1]);
data.handles.H_Panel_Bottom_Middle = uipanel('Parent',data.handles.H_Panel_Bottom,'Units','pixels','Position',[1+BottomLeftWidth 1 BottomMiddleWidth BottomHeight],'Background',[1,1,1]);
data.handles.H_Panel_Bottom_Left = uipanel('Parent',data.handles.H_Panel_Bottom,'Units','pixels','Position',[1 1 BottomLeftWidth BottomHeight],'Background',[1,1,1]);

data.handles.H_Axes = axes('Parent',data.handles.H_Panel_Middle,'Position',[.05,.05,.9,.9],'FontWeight','bold','FontSize',10);

data.handles.H_Button_L_Bottom = uicontrol(data.handles.H_Panel_Bottom_Middle,'Style','pushbutton','String','<-','Position',[Padding+ArrowButtonWidth Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Button_LL_Bottom = uicontrol(data.handles.H_Panel_Bottom_Middle,'Style','pushbutton','String','<<--','Position',[Padding Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Button_R_Bottom = uicontrol(data.handles.H_Panel_Bottom_Middle,'Style','pushbutton','String','->','Position',[BottomMiddleWidth-2*ArrowButtonWidth-Padding Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Button_RR_Bottom = uicontrol(data.handles.H_Panel_Bottom_Middle,'Style','pushbutton','String','-->>','Position',[BottomMiddleWidth-ArrowButtonWidth-Padding Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Text_FN_Bottom = uicontrol('Parent',data.handles.H_Panel_Bottom_Middle,'Style','text','String','counts02','Units','pixels','Position',[(BottomMiddleWidth-SelectButtonWidth)/2 Padding SelectButtonWidth SelectButtonHeight],'Background',[1,1,1],'FontSize',14,'FontWeight','Bold');

data.handles.H_Button_L_Top = uicontrol(data.handles.H_Panel_Top_Middle,'Style','pushbutton','String','<-','Position',[Padding+ArrowButtonWidth Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Button_LL_Top = uicontrol(data.handles.H_Panel_Top_Middle,'Style','pushbutton','String','<<--','Position',[Padding Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Button_R_Top = uicontrol(data.handles.H_Panel_Top_Middle,'Style','pushbutton','String','->','Position',[BottomMiddleWidth-2*ArrowButtonWidth-Padding Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Button_RR_Top = uicontrol(data.handles.H_Panel_Top_Middle,'Style','pushbutton','String','-->>','Position',[BottomMiddleWidth-ArrowButtonWidth-Padding Padding ArrowButtonWidth ArrowButtonHeight],'FontWeight','demi','FontSize',12);
data.handles.H_Text_FN_Top = uicontrol('Parent',data.handles.H_Panel_Top_Middle,'Style','text','String','counts01','Units','pixels','Position',[(BottomMiddleWidth-SelectButtonWidth)/2 Padding SelectButtonWidth SelectButtonHeight],'Background',[1,1,1],'FontSize',14,'FontWeight','Bold');

data.handles.H_Panel_Color_Bottom_Right = uipanel('Parent',data.handles.H_Panel_Bottom_Right,'Units','pixels','Position',[Padding Padding BottomLeftWidth-2*Padding SelectButtonHeight],'Background',Color_One);
data.handles.H_Panel_Color_Top_Right = uipanel('Parent',data.handles.H_Panel_Top_Right,'Units','pixels','Position',[Padding Padding TopLeftWidth-2*Padding SelectButtonHeight],'Background',Color_Two);

data.handles.H_Panel_Color_Bottom_Left = uipanel('Parent',data.handles.H_Panel_Bottom_Left,'Units','pixels','Position',[Padding Padding BottomLeftWidth-2*Padding SelectButtonHeight],'Background',Color_One);
data.handles.H_Panel_Color_Top_Left = uipanel('Parent',data.handles.H_Panel_Top_Left,'Units','pixels','Position',[Padding Padding TopLeftWidth-2*Padding SelectButtonHeight],'Background',Color_Two);



set(0,'UserData',data);

