function varargout = Main(varargin)
% MAIN MATLAB code for Main.fig
%      MAIN, by itself, creates a new MAIN or raises the existing
%      singleton*.
%
%      H = MAIN returns the handle to a new MAIN or the handle to
%      the existing singleton*.
%
%      MAIN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN.M with the given input arguments.
%
%      MAIN('Property','Value',...) creates a new MAIN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Main_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Main_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Main

% Last Modified by GUIDE v2.5 07-Dec-2014 00:00:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Main_OpeningFcn, ...
                   'gui_OutputFcn',  @Main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Main is made visible.
function Main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Main (see VARARGIN)

% Choose default command line output for Main
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global usr;
[FileName,PathName] = uigetfile('*.jpg','Select an image');
usr=imread(strcat(PathName,FileName));


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global usr;
axes(handles.axes1);
imshow(usr);
title('Original Image');


load regioncoordinates;  %load the region coordinates that are stored in a MAT-file. 'L*' or brightness layer, chromaticity layer 'a*' indicating where color falls along the red-green axis, and chromaticity layer 'b*' indicating where the color falls along the blue-yellow axis

nColors = 6;
sample_regions = false([size(usr,1) size(usr,2) nColors]);

for count = 1:nColors
  sample_regions(:,:,count) = roipoly(usr,region_coordinates(:,1,count),...
                                      region_coordinates(:,2,count));
end


cform = makecform('srgb2lab'); %Convert your fabric RGB image into an L*a*b* image using rgb2lab .
lab_usr = applycform(usr,cform);%convert it into l*a*b from rgb using cform and applycform %Calculate the mean a* and b* value for each area that you extracted with roipoly. These values serve as your color markers in a*b* space.

a = lab_usr(:,:,2);
b = lab_usr(:,:,3);
color_markers = repmat(0, [nColors, 2]);

for count = 1:nColors
  color_markers(count,1) = mean2(a(sample_regions(:,:,count)));
  color_markers(count,2) = mean2(b(sample_regions(:,:,count)));
end

disp(sprintf('[%0.3f,%0.3f]',color_markers(2,1),color_markers(2,2))); %the average color of the red sample region in a*b* space 

%Each color marker now has an a* and a b* value. You can classify each pixel in the lab_fabric image by calculating the Euclidean distance between that pixel and each color marker. The smallest distance will tell you that the pixel most closely matches that color marker. For example, if the distance between a pixel and the red color marker is the smallest, then the pixel would be labeled as a red pixel.
%Create an array that contains your color labels, i.e., 0 = background, 1 = red, 2 = green, 3 = purple, 4 = magenta, and 5 = yellow.

color_labels = 0:nColors-1;

a = double(a);%Initialize matrices to be used in the nearest neighbor classification.
b = double(b);%Initialize matrices to be used in the nearest neighbor classification.
distance = repmat(0,[size(a), nColors]);

%Perform classification.
for count = 1:nColors
  distance(:,:,count) = ( (a - color_markers(count,1)).^2 + ...
                      (b - color_markers(count,2)).^2 ).^0.5;
end

[value, label] = min(distance,[],3);
label = color_labels(label);
clear value distance;  


%The label matrix contains a color label for each pixel in the fabric image. Use the label matrix to separate objects in the original fabric image by color.
rgb_label = repmat(label,[1 1 3]);
segmented_images = repmat(uint8(0),[size(usr), nColors]);

for count = 1:nColors
  color = usr;
  color(rgb_label ~= color_labels(count)) = 0;
  segmented_images(:,:,:,count) = color;
end

axes(handles.axes2);
imshow(segmented_images(:,:,:,2)), title('Class M Segmentation');  

axes(handles.axes3);
imshow(segmented_images(:,:,:,3)), title('Class G Segmentation'); 

axes(handles.axes4);
imshow(segmented_images(:,:,:,4)), title('Class O Segmentation');  

axes(handles.axes5);
imshow(segmented_images(:,:,:,5)), title('Class B Segmentation');  

axes(handles.axes6);
imshow(segmented_images(:,:,:,6)), title('Class K Segmentation');   


%You can see how well the nearest neighbor classification separated the different color populations by plotting the 
%a* and b* values of pixels that were classified into separate colors. For display purposes, label each point with its color label.
purple = [119/255 73/255 152/255];

plot_labels = {'k', 'r', 'g', purple, 'm', 'y'};

figure
for count = 1:nColors
  plot(a(label==count-1),b(label==count-1),'.','MarkerEdgeColor', ...
       plot_labels{count}, 'MarkerFaceColor', plot_labels{count});
  hold on;
end

title('Scatterplot of the segmented Tempreature Areas');
xlabel('Tempreature Scale');
ylabel('Density Scale');


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
exit
