close all; clear; clc;

W = 10;
H = 10;

Nx = 3;
Ny = 3;

dx = W / (Nx-1);
dy = H / (Ny-1);

p = zeros(2,Nx*Ny);
cl = zeros(3, 2 * (Nx-1) * (Ny-1));

index = 0;
for i = 1:Ny

    y = (i-1) * dy;
    
    for j = 1:Nx

        x = (j-1) * dx;
        index = index + 1;
        p(1, index) = x;
        p(2, index) = y;

    end
end

index = 0;
for i = 1:Ny-1
    
    for j = 1:Nx-1

        index1 = j + (i-1) * Nx;
        index2 = index1 + 1;
        index3 = index2 + Nx;
        index4 = index1 + Nx;

        index = index + 1;
        cl(:,index) = [index1; index3; index4];

        index = index + 1;
        cl(:,index) = [index1; index2; index3];

    end
end

hold all;
patch('faces', cl', 'Vertices', p', 'facecolor', 'c', 'edgecolor', 'k');
plot(p(1,:), p(2,:), 'o', 'color', 'k');

p'
cl'
