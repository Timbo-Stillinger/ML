function net=runNN(predictors,response)
                net = feedforwardnet([33 33]);
                net=configure(net,predictors',response');
                net.trainFcn = 'trainscg';
                net.trainParam.max_fail = 100;
                net = train(net, predictors', ...
                response');
end