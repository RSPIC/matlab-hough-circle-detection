clc; clear; close all;
%% Preprossecing

red = imread("2.png");
if ndims(red)==3
   red = rgb2gray(red);
end
gaussianFilter = fspecial('gaussian',15, 15);
gaus = imfilter(red, gaussianFilter,'symmetric');
subplot(2,4,1)
imshow(gaus),title("gaussian")

levels = multithresh(red, 12);
BW = imquantize(gaus,levels);
L = imfill(BW);
subplot(2,4,2)
imshow(label2rgb(L)),title("multithresh")

level = 8;
BW(BW<level)=0;
BW(BW>=level)=1;
subplot(2,4,3)
imshow(BW),title("threathod")

se = strel('disk',3);
ED = imopen(BW, se);
subplot(2,4,4)
imshow(ED),title("open")

se = strel('disk',10);
ED2 = imclose(ED, se);
subplot(2,4,5)
imshow(ED2),title("close")

img_edges = edge(ED2, 'Canny');
subplot(2,4,6)
imshow(img_edges),title("canny")

se = strel('disk',1);
ED3 = imdilate(img_edges,se);


%% Circle Hough Transform

radius_range = [40, 200];
r_min = radius_range(1);
r_max = radius_range(2);
r_num = 1;
numpeaks = 1;%同一个半径查找几次圆
centers = zeros(r_num * numpeaks, 4);%一二列记录坐标，第三列为票数,第四列为半径
%radii = zeros(size(centers,1),1); 优化删除
row_num = 0;
circle_num=2;%想要画几个圆
division_times = 100;%步进大小
    for radius = linspace(r_min, r_max, division_times) %半径的步进大小,除以(n+1)，得到N个分割数值
        % Compute Hough accumulator array for finding circles.
        H = zeros(size(ED3));%投票矩阵/参数矩阵
        for x = 1 : size(ED3, 2)
            for y = 1 : size(ED3, 1)
                if (ED3(y,x))
                    for theta = linspace(0, 2 * pi, 360)
                        a = round(x + radius * cos(theta));                
                        b = round(y + radius * sin(theta));
                        if (a > 0 && a <= size(H, 2) && b > 0 && b <= size(H,1))%圆心坐标在图像范围内
                            H(b,a) = H(b,a) + 1;
                        end
                    end
                end
            end
        end

        % Find peaks in a Hough accumulator array
        threshold = 0.8 * max(H(:)); % which values of H are considered to be peaks
        %max(H(:));
        nHoodSize = floor(size(H) / 100.0) * 2 + 1; % Size of the suppression neighborhood, [M N]
        peaks = zeros(numpeaks, 4);
        num = 0;
        while(num < numpeaks) %指定半径下，寻找多少次峰值点
            maxH = max(H(:));
            if (maxH >= threshold)
                num = num + 1;
                [ra,c] = find(H == maxH);
                peaks(num,:) = [ra(1),c(1),max(H(:)),radius]; %记录圆心，票数，半径
                rStart = max(1, ra - (nHoodSize(1) - 1) / 2);
                rEnd = min(size(H,1), ra + (nHoodSize(1) - 1) / 2);
                cStart = max(1, c - (nHoodSize(2) - 1) / 2);
                cEnd = min(size(H,2), c + (nHoodSize(2) - 1) / 2);
                for i = rStart : rEnd   %多次寻找峰值点下，消去同个圆心周围区域影响
                    for j = cStart : cEnd
                            H(i,j) = 0;
                    end
                end
            else
                break;          
            end
        end
        peaks = peaks(1:num, :);        
        if (size(peaks,1) > 0) %peaks多少行，即测出多少个peaks
            row_num_new = row_num + size(peaks,1);
            centers(row_num + 1:row_num_new,:) = peaks;%迭代统计入centers
            %radii(row_num + 1:row_num_new) = radius;
            row_num = row_num_new;       
        end
        
    end
centers = centers(1:row_num,:);
%radii = centers(1:row_num,4); 半径存入centers的第四列
%centers %test
vote_list = sortrows(centers,3,"descend");
centers = vote_list(1:circle_num,:); %取指定数量的圆
%centers %test

%% Draw this circle on the image

figure();
imshow(ED3);
whos("centers")
size(centers,1)
for i= 1:size(centers,1)
    hold on;
    r = centers(i,4);
    center_x = centers(i, 2);
    center_y = centers(i, 1);
    theta = linspace(0, 2 * pi, 360);
    xx = center_x + r * cos(theta);
    yy = center_y + r * sin(theta);
    plot(xx, yy,'r', 'LineWidth', 1);
    hold off;
end
[r center_y center_x]