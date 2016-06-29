%Creates an ensemble average and bar plot emg figure and aligns any
%unaligned peaks

%enter the target trials that you are trying to plot
targetTrials = [1,2,3,4];
targetTrials = [2,6,7,8];
cond = 2; %should be 2 or 1 based on which group you want to process
numberSubjs = 7;

%window size for aligning trials (these work for the resistive robot fig
if cond == 2
    window = 50;
else
    window = 100;
end
%window = 100;

%muscle names and order
muscle = {'VM','RF','MH','LH','TA','MG','SO','GM'};

k = 7;
for k = 1:size(muscle,2)
    
    %load the file
    cd 'C:\Users\E. Peter Washabaugh\Google Drive\Papers\Completed\Resistive Robot Paper\Resistive Robot Paper\EMG Postprocess Unaligned'
    
    file = ['Ensemble_',muscle{k},'_EMG.txt'];
    Data = importdata(file);
    
    cd 'C:\Users\E. Peter Washabaugh\Documents\GitHub\ABME-Resistive-Robot-EMG-Fig'
    
    %works to switch trials 6 and 7 so they are in ascending order
    for i = 6:10:66;
        store = Data.data(i+1,:);
        Data.data(i+1,:) = Data.data(i,:);
        Data.data(i,:) = store;
    end
        
    %removes any spurious subjects or muscles
    filter = zeros(1,length(Data.textdata))';
    if strcmp(file(10:11),'SO')
        numberSubjs = numberSubjs - 1;
        for i = 1:length(Data.textdata)
            
            if strcmp(Data.textdata{i,1},'MC061215')
                filter(i) = 1;
            end
        end
    end
    filter = logical(filter);
    
    Data.data(filter,:) = [];
    
    %captures the target trials for an ensemble average
    target = zeros(1,length(targetTrials)*numberSubjs);
    
    for i = 1:numberSubjs
        target(length(targetTrials)*(i-1)+1:length(targetTrials)*(i-1)+length(targetTrials)) ...
            = targetTrials+(10*(i-1));
    end
    targetData = Data.data(target,1:(length(Data.data)/2)-1);
    
    %takes an ensemble average of the data
    ensData = zeros(length(targetTrials),size(targetData,2));
    for i = 1:length(targetTrials)
        for j = 1:size(targetData,2)
            ensData(i,j) = mean(targetData(i:length(targetTrials):end,j));
        end
    end
    
    %calculates average stance and swing values for barplots
    avgStance = zeros(size(targetTrials));
    semStance = zeros(size(targetTrials));
    avgSwing = zeros(size(targetTrials));
    semSwing = zeros(size(targetTrials));
    for i = 1:length(targetTrials)
        avgStance(i) = mean(ensData(i,1:size(ensData,2)/2));
        semStance(i) = std(ensData(i,1:size(ensData,2)/2))/sqrt(numberSubjs);
        avgSwing(i) = mean(ensData(i,size(ensData,2)/2:end));
        semSwing(i) = std(ensData(i,size(ensData,2)/2:end))/sqrt(numberSubjs);
    end
    
    
%     figure;
%     subplot(2,1,1)
%     plot(ensData')
    
    %entire shifting algorithm. Shifts all plots to the max of the baseline
    %trial
    for i = 1:size(ensData,1)
        if i == 1
            [startY,startI] = max(ensData(i,:));
        else
            if (startI - window) <= 0
                [shiftY,shiftI] = max(ensData(i,1:startI+window,:));
                [shiftY1,shiftI1] = max(ensData(i,size(ensData,2)+(startI-window):end));
                %0
                if shiftY > shiftY1
                    shiftNum = startI - shiftI;
                    ensData(i,:) = circshift(ensData(i,:),[0,shiftNum]);
                    %  a = 1
                else
                    shiftNum = startI + (size(ensData(i,size(ensData,2)+(startI-window):end),2)-shiftI1);
                    ensData(i,:) = circshift(ensData(i,:),[0,shiftNum]);
                    %   a = 2
                end
            elseif (startI + window) >= size(ensData,2)
                [shiftY,shiftI] = max(ensData(i,startI-window:end));
                [shiftY1,shiftI1] = max(ensData(i,1:(startI+window-size(ensData,2))));
                %1
                if shiftY > shiftY1
                    shiftNum = startI - shiftI;
                    ensData(i,:) = circshift(ensData(i,:),[0,shiftNum]);
                    %  a=1
                else
                    shiftNum = -((size(ensData(i,:),2)-startI)+shiftI1);
                    ensData(i,:) = circshift(ensData(i,:),[0,shiftNum]);
                    %   a = 2
                end
            else
                [Y,shiftI] = max(ensData(i,startI-window:startI+window));
                shiftNum = window - shiftI;
                ensData(i,:) = circshift(ensData(i,:),[0,shiftNum]);
                %2
            end
        end
    end
%     subplot(2,1,2)
%     plot(ensData')
    %clf
    
    
    %plots all of the data
    Robotplot = subplot(2,4,k);
    bars = [avgStance,avgSwing];
    error = [semStance,semSwing];
    set(gcf,'Color','w')
    
    %color scheme
    co = [0 0   0;
        .6  .6     .6;
        0         0.4470    0.7410;
        0.8500    0.3250    0.0980;
        0.9290    0.6940    0.1250;
        0.4940    0.1840    0.5560;
        0.4660    0.6740    0.1880;
        0.3010    0.7450    0.9330;
        0.6350    0.0780    0.1840];
    
    %greyscale color scheme
    cog = zeros(size(co));
    for i = 1:5-1
        cog(i+1,:) = cog(i+1,:)+.2*i;
    end

    %set(gca,'ColorOrder',colorset)
    hold all
    
    %controls tick marks and axis limits
    barSpace = [linspace(10,40,length(targetTrials)),linspace(60,90,length(targetTrials))];
    xlab = linspace(0,100,11);
    xticklab = {'0','10','20','30','40','50','60','70','80','90','100'};
    newY = [0,ceil(max(max(ensData')))];
    for i = 1:10;
        if mod(newY(2),10) == 0
            break
        else
            newY(2) = newY(2)+1;
        end
    end
    %newY = [0 70];
    
    %change the color scheme to one of the ones above
    color = co;
    
    leg = zeros(size(ensData,1),1);
    for i = 1:size(ensData,1)
        
        [AX,H1,H2] = plotyy([barSpace(i),barSpace(i+length(targetTrials))],...
            [bars(i),bars(i+length(targetTrials))],linspace(0,100,1000),...
            ensData(i,:)','bar','plot');
        
        %sets colors to be trial by trial
        set(H2,'LineWidth',3)
        if i == 1
            if cond == 1
            set(H2,'Color',color(i,:));
            set(H1,'FaceColor',color(i,:),'EdgeColor','none','BarWidth',.2);
            elseif cond == 2
            set(H2,'Color',color(i+1,:));
            set(H1,'FaceColor',color(i+1,:),'EdgeColor','none','BarWidth',.2);
            end
        elseif (size(targetTrials,2) == 4) && i > 1    
            
            if cond == 1
                set(H2,'Color',color(i,:));
                set(H1,'FaceColor',color(i,:),'EdgeColor','none','BarWidth',.2);
            elseif cond == 2
                if i == 2
                set(H2,'Color',color(7,:)*.75);
                set(H1,'FaceColor',color(7,:)*.75,'EdgeColor','none','BarWidth',.2);
                else
                set(H2,'Color',color(i,:));
                set(H1,'FaceColor',color(i,:),'EdgeColor','none','BarWidth',.2);
                end
            end
        elseif (size(targetTrials,2) == 5) && i > 1
            set(H2,'Color',color(i+1,:));
            set(H1,'FaceColor',color(i+1,:),'EdgeColor','none','BarWidth',.15);
        end
        
        leg(i) = H1;
        
        %keeps color scheme the same as before
%         set(H2,'Color',color(i,:));
%         if (size(targetTrials,2) == 5)
%             set(H1,'FaceColor',color(i,:),'EdgeColor','none','BarWidth',.15);
%         elseif (size(targetTrials,2) == 4)
%             set(H1,'FaceColor',color(i,:),'EdgeColor','none','BarWidth',.20);
%         end
        
        set(AX(1),'XLim',[0,100],'FontName','Arial','FontSize',12,'FontWeight','bold','LineWidth',2,'YLim',newY,'Ytick',linspace(newY(1),newY(2),6),'Xtick',[25,75],'Xticklabel',{'Avg Stance','Avg Swing'},'TickLength',[0 0],'Tickdir','out','XAxisLocation','bottom')
        set(AX(2),'XLim',[0,100],'FontName','Arial','FontSize',12,'FontWeight','bold','LineWidth',2,'YLim',newY,'Ytick',linspace(newY(1),newY(2),6),'YColor','w','Xtick',xlab,'Xticklabel',{},'Tickdir','in','XAxisLocation','bottom')

        %set(AX(1),'visible','off')
        alpha(H1,.2) %Changes the transparency of the bars in the plot

    end
        
    
    if k == size(muscle,2)
        if cond == 1
            legend('pre-BW','pre-BWNR','BWMR','BWHR')
        elseif cond == 2
            legend('pre-BWNR','TMLR','TMMR','TMHR')
        end
        legend('boxoff')
    end
    
    errorbar(barSpace,bars,error,'k','LineWidth',1.1,'LineStyle','none')

    %set titles and labels for axes
    title(muscle{k},'FontName','Arial','FontSize',22,'FontWeight','bold')
    if (k == 1) || (k == 5)
    ylabel(AX(1),'MVC (%)','FontName','Arial','FontSize',16,'FontWeight','bold')
    end
    if k > 4
    xlabel(AX(1),'Gait Cycle (%)','FontName','Arial','FontSize',16,'FontWeight','bold')
    end
    box off
    hold off
end

