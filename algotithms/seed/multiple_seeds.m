close all;
clc;
clear all;
% filename= '6';
% 
% % iminfo = dicominfo(filename)
% I = dicomread(filename);
% I = I + 2000;
% I = rescale(I,0,1);
% I = imadjust(I,[0.7 0.8],[0 1]);

addpath(genpath('../utils'))
fname = {'img_0308_a','img_0305_a','img_0299_a','img_0300_a','img_0122_e','img_0125_e','img_0144_e',...
         'img_0141_e','img_0142_e','img_0143_e','img_0089_e','img_0102_f','img_0105_f','img_0108_f',...
         'img_0111_f','img_0114_f','img_0100_f','img_0071_d','img_0092_c', 'img_0289_a','img_0301_a'};
I = read_image_double_py(fname{1,21});


prompt = 'Enter number of neighbours (ex. 4 or 8): ';
neigbr_number = input(prompt);

prompt = ['Enter mean type' newline ...
    '1) mean' newline ...
    '2) median' newline ':']
mean_type = input(prompt)

prompt = 'Enter region max distance [0 - 1]: '
reg_maxdist = input(prompt);



if(isempty(neigbr_number))
    
    neigbr_number = 4;
    
end

imshow(I,[]);
[xi,yi] = ginput;
xi = round(xi);
yi = round(yi);

number_of_seeds = size(xi,1);


J = regiongrowing(I,neigbr_number,xi,yi,number_of_seeds,reg_maxdist,mean_type); 
% figure;
% imshow([J,J>1]);
% figure;imshow(label2rgb(J))


% for i=1:max(J(:))
%     figure('Name',int2str(i));
%     imshow(J==i);
%     title(int2str(i));
% end

J = J > 1;

gray_img = bin_to_gray(J,I);
addpath('../utils')
render_seg_subplots(I,J);

% position =  [1 50];
% value = [555 pi];
% 
% RGB = insertText(I,position,value,'AnchorPoint','LeftBottom');
% 
% figure;
% imshow(RGB)

addpath(genpath('../classification'))
[organs,props] = classify_mult_organs(I, J,gray_img);
% figure;
% imshow([J,gray_img])
 


   
function [output_img,b]=regiongrowing(input_img,neigbr_number,y,x,number_of_seeds,reg_maxdist,mean_type)

if(exist('reg_maxdist','var')==0), reg_maxdist=0.07; end
% if(exist('y','var')==0), figure, imshow(input_img,[]); [y,x]=getpts;
%     y=round(y(1)); x=round(x(1)); end

output_img = zeros(size(input_img)); % Out

input_img_size = size(input_img); % Dimensions of input image

%reg_mean = input_img(x,y) % The mean of the segmented region
region_size = 1; % Number of pixels in region

% Free memory to store neighbours of the (segmented) region
memory_free = 10000; memory_possesed=0;
neigbor_list = zeros(memory_free,3); 

pixdist=0; % Distance of the region newest pixel to the regio mean

% Neighbor locations (footprint)
if(neigbr_number==4)
    neigb_locations=[-1 0
                      1 0
                      0 -1
                      0 1];
elseif(neigbr_number==8)
    neigb_locations=[-1 0
                     -1 1
                      1 1 
                      1 -1
                     -1 -1
                      1 0
                      0 -1
                      0 1]; 
end

% Start regiogrowing until distance between regio and posible new pixels become
% higher than a certain treshold
xi = x;
yi = y;
total_regions_size = 0;
region_size = 0;
for i = 1:number_of_seeds
    x = xi(i);
    y = yi(i);
    reg_mean = input_img(x,y);
    
    wrong_seed_selected = logical(0);
    if(output_img(x,y) ~= 0)
        wrong_seed_selected = logical(1);
    end
    
    total_regions_size = total_regions_size + region_size;
    region_size = 1;
    
    pixdist = 0;
    memory_free = 10000; memory_possesed=0;
    neigbor_list = zeros(memory_free,3);
    
    while(pixdist<reg_maxdist && total_regions_size<numel(input_img) && wrong_seed_selected==0)
        % Add new neighbors pixels
        for j=1:neigbr_number,
            % Calculate the neighbour coordinate
            xn = x +neigb_locations(j,1); yn = y +neigb_locations(j,2);

            
            % Check if neighbour is inside or outside the image
            ins=(xn>=1)&&(yn>=1)&&(xn<=input_img_size(1))&&(yn<=input_img_size(2));

            % Add neighbor if inside and not already part of the segmented area
            if(ins&&(output_img(xn,yn)==0)) 
                    memory_possesed = memory_possesed+1;
                    neigbor_list(memory_possesed,:) = [xn yn input_img(xn,yn)]; 
                    output_img(xn,yn)=1;
            end
        end

        % Add a new block of free memory
        if(memory_possesed+10>memory_free), memory_free=memory_free+10000; neigbor_list((memory_possesed+1):memory_free,:)=0; end

        % Add pixel with intensity nearest to the mean of the region, to the region
        dist = abs(neigbor_list(1:memory_possesed,3)-reg_mean);
        [pixdist, index] = min(dist);
        output_img(x,y)=(i+1); region_size=region_size+1;

        % Calculate the new mean of the region
        
        if(mean_type==1)
            reg_mean= (reg_mean*region_size + neigbor_list(index,3))/(region_size+1);
        else
            ind = find(neigbor_list(:,3)>0);
            neigbor_list(ind,3);
            reg_mean = median(neigbor_list(ind,3));
        end

        % Save the x and y coordinates of the pixel (for the neighbour add proccess)
        x = neigbor_list(index,1); y = neigbor_list(index,2);

        % Remove the pixel from the neighbour (check) list
        neigbor_list(index,:)=[];
        memory_possesed=memory_possesed-1;

    end
end
% Return the segmented area as logical matrix
% output_img=output_img>1;

end

function gray_img = bin_to_gray(bin_img,gray_img)
    for i=1:size(bin_img,1)
        for j=1:size(bin_img,2)
            if(bin_img(i,j) == 0)
                gray_img(i,j) = 0;
            end
        end
    end
end






