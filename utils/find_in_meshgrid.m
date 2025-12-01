function [y_s, x_s] = find_in_meshgrid(X, Y, ptx, pty)
    % Find the indices of the closest point to (ptx, pty)
    % in a provided meshgrid
    %
    % Parameters
    % ----------
    % X : X meshgrid
    % Y : Y meshgrid
    % ptx : x-coordinate of point
    % pty : y-coordiante of point
    %
    % Returns
    % -------
    % y_s : closest row index of provided point
    % x_s : closest column index of provided point

    % get squared distances between point and meshgrid points
    distances_sq = (X - ptx).^2 + (Y - pty).^2;

    % get closest point linear index
    [~, linear_idx] = min(distances_sq(:));

    % convert to row/column
    [y_s, x_s] = ind2sub(size(X), linear_idx);
end