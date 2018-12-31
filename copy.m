clear all;
clc;
close all;
clf('reset'); //clear currnt figure window
s=serial('COM4','BAUD', 9600); % Make sure the baud rate and COM port is 
                              % same as in Arduino IDE
//create serial port object 
fopen(s);//connect serial port object to device that is give input or take output from the port
vid1 = videoinput('winvideo', 1);  %create webcam object //Create video input object
right='r';
left='l';
noface='n';
straight='s';
%detector = vision.CascadeObjectDetector(); % Create a detector for face using Viola-Jones
detector1 = vision.CascadeObjectDetector('EyepairBig'); %create detector for eyepair
//Detect objects using the Viola-Jones algorithm
//The cascade object detector uses the Viola-Jones algorithm to detect people’s faces, noses, eyes, mouth, or upper body. 
while true % Infinite loop to continuously detect the face
    
    
    vid=getsnapshot(vid1);  %get a snapshot of webcam
    vid = rgb2gray(vid);    %convert to grayscale
    img = flip(vid, 2); % Flips the image horizontally
    
     bbox = step(detector1, img); % Creating bounding box using detector  
      
     if ~ isempty(bbox)  %if face exists 
         biggest_box=1;     
         for i=1:rank(bbox) %find the biggest face
             if bbox(i,3)>bbox(biggest_box,3)
                 biggest_box=i;
             end
         end
         faceImage = imcrop(img,bbox(biggest_box,:)); % extract the face from the image
         bboxeyes = step(detector1, faceImage); % locations of the eyepair using detector
         
         subplot(2,2,1),subimage(img); hold on; % Displays full image
         for i=1:size(bbox,1)    %draw all the regions that contain face
             rectangle('position', bbox(i, :), 'lineWidth', 2, 'edgeColor', 'y');
         end
         
         subplot(2,2,3),subimage(faceImage);     %display face image
                 
         if ~ isempty(bboxeyes)  %check it eyepair is available
             
             biggest_box_eyes=1;     
             for i=1:rank(bboxeyes) %find the biggest eyepair
                 if bboxeyes(i,3)>bboxeyes(biggest_box_eyes,3)
                     biggest_box_eyes=i;
                 end
             end
             
             bboxeyeshalf=[bboxeyes(biggest_box_eyes,1),bboxeyes(biggest_box_eyes,2),bboxeyes(biggest_box_eyes,3)/3,bboxeyes(biggest_box_eyes,4)];   %resize the eyepair width in half
             
             eyesImage = imcrop(faceImage,bboxeyeshalf(1,:));    %extract the half eyepair from the face image
             eyesImage = imadjust(eyesImage);    %adjust contrast

             r = bboxeyeshalf(1,4)/4;
             [centers, radii, metric] = imfindcircles(eyesImage, [floor(r-r/4) floor(r+r/2)], 'ObjectPolarity','dark', 'Sensitivity', 0.93); % Hough Transform
             [M,I] = sort(radii, 'descend');
             
                 
             eyesPositions = centers;
                 
             subplot(2,2,2),subimage(eyesImage); hold on;
              
             viscircles(centers, radii,'EdgeColor','b');
                  
             if ~isempty(centers)
                pupil_x=centers(1);
                disL=abs(0-pupil_x);    %distance from left edge to center point
                disR=abs(bboxeyes(1,3)/3-pupil_x);%distance from right edge to center point
        
                if disL>disR+16 //if the white part of eye is more in left side
                    disp(right);
                    servalue='r';
                    fprintf(s,servalue);//transfer input r to arduino meanf right
                else if disR>disL//if the white part of eye is more in left side
                    disp(left);
                    servalue='l';
                    fprintf(s,servalue);//transfer input l to arduino means left
                    else
                       disp(straight);
                       servalue='s';
                       fprintf(s,servalue);//transfer input s to arduino means straight
                    end
                end
     
             end          
         end
     else
        servalue='n';
        fprintf(s,servalue);//transfer input n to arduino means stop
        disp(noface);
     end

     set(gca,'XtickLabel',[],'YtickLabel',[]);

   hold off;
end

