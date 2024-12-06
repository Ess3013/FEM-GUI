function hex_color = stress_color_gradient(value)
    % STRESS_COLOR_GRADIENT Convert a decimal value to a hex color code
    % Input: value between 0 and 1
    % Output: Hex color code transitioning through blue, cyan, green, yellow, orange, red
    
    % Validate input
    if ~isnumeric(value) || value < 0 || value > 1
        error('Input must be a decimal between 0 and 1');
    end
    
    % Define color points
    colors = [
        0.0, 0, 0, 1;      % Blue
        0.2, 0, 1, 1;      % Cyan
        0.4, 0, 1, 0;      % Green
        0.6, 1, 1, 0;      % Yellow
        0.8, 1, 0.5, 0;    % Orange
        1.0, 1, 0, 0       % Red
    ];
    
    % Find the appropriate color segments
    for i = 1:(size(colors,1)-1)
        if value <= colors(i+1,1)
            % Interpolate between current color and next color
            t = (value - colors(i,1)) / (colors(i+1,1) - colors(i,1));
            rgb = colors(i,2:4) + t * (colors(i+1,2:4) - colors(i,2:4));
            break;
        end
    end
    
    % Convert RGB to hex
    rgb_values = round(rgb * 255);
    hex_color = sprintf('#%02X%02X%02X', rgb_values(1), rgb_values(2), rgb_values(3));
end

% Example usage:
% blue_color = stress_color_gradient(0)     % Blue
% cyan_color = stress_color_gradient(0.1)   % Cyan
% green_color = stress_color_gradient(0.4)  % Green
% yellow_color = stress_color_gradient(0.6) % Yellow
% orange_color = stress_color_gradient(0.8) % Orange
% red_color = stress_color_gradient(1)      % Red