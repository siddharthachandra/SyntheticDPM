function new = removePadding(im),
    mim = mean(im,3);
    [R C] = size(mim);
    for t = 1:1:R,
        if any(mim(t,:)<240),
            break;
        end
    end
    for b = R:-1:1,
        if any(mim(b,:)<240),
            break;
        end
    end
    for l = 1:1:C,
        if any(mim(:,l)<240),
            break;
        end
    end
    for r = C:-1:1,
        if any(mim(:,r)<240),
            break;
        end
    end
    new = im(t:b,l:r,:);
end
