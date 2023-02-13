%Look up subject heigh based on participant number, return in meters

function height = lookupHeight (id)

    % Note that heights are listed in inches, 
    % will be converted to meters before returning
    if id == "OA01" 
        height = 66;
    elseif id == "OA02"
        height = 64;
    elseif id == "OA03"
        height = 77;
    elseif id == "OA04"
        height = 69;
    elseif id == "OA05"
        height = 66;
    elseif id == "OA06"
        height = 72;
    elseif id == "OA07"
        height = 66;
    elseif id == "OA08"
        height = 65;
    elseif id == "OA09"
        height = 69;
    elseif id == "OA10"
        height = 66;
    elseif id == "OA11"
        height = 69;
    elseif id == "OA12"
        height = 61;
    elseif id == "OA13"
        height = 73;
    elseif id == "OA14"
        height = 73;
    elseif id == "OA15"
        height = 71;
    elseif id == "OA16"
        height = 66;
    elseif id == "OA17"
        height = 59;
    elseif id == "OA18"
        height = 70;
    elseif id == "OA19"
        height = 71;
    elseif id == "OA20"
        height = 68;
    else
        error("Unknown participant ID entered into lookupHeight.");
    end
    
    height = height * 0.0254; %convert to meters
    return;
end
