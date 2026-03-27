% D-POWTA Conflict Detection Utility
%
% Usage:
%   is_conflict = is_in_conflict(conflict_set, j, h)
%
% Author: KG-DREA
% Date: 2026-03-27

function is_conflict = is_in_conflict(conflict_set, j, h)
    is_conflict = false;

    if isempty(conflict_set) || size(conflict_set, 1) == 0 || h == 0
        return;
    end

    matches = find(conflict_set(:, 1) == j & conflict_set(:, 2) == h);
    if ~isempty(matches)
        is_conflict = true;
    end
end