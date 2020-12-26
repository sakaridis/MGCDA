% Licensed under the CC BY-NC 4.0 license (https://creativecommons.org/licenses/by-nc/4.0/)
function n = nTrials(inlierRatio, samples, p)

n = log(1 - p) / log(1 - inlierRatio ^ samples);

end