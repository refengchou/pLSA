tic 
close all

clear

%============================
% Custom input Parameters
%============================

q = 1;

numIteration = 200;

numLatentClass = 3; 

beta = 1

ratings = zeros(943, 1682);

nowSet = now;

[numUser numMovie] = size(ratings);


for countFile = 1:5
	
	filename = ['u',num2str(countFile),'.base'];
	
	M = dlmread(filename);
	
	[numBase, t] = size(M);
	
	figure;
	
	
	
	for i = 1:numBase 
		
		ratings(M(i,1),M(i,2)) = M(i,3);
		
	end
	
		
		
	meanUser = mean(ratings,2);
	
	edges = [ 0 1 2 3 4 5];
	
	n=histc(ratings,edges,2);
	
	numRatingUser = n(:,2)+n(:,3)+n(:,4) + n(:,5) + n(:,6);
	
	meanUser = sum(ratings,2) ./ numRatingUser;
	%
	% stdAll = std2(ratings);
	% VarUser = (var(ratings,0,2) + q*stdAll) ./ (numRatingUser + q);
	% stdUser = sqrt(VarUser);
	
	VarUser = 0;
	
	for i =1:numUser
		
		acc = 0;
		count = 0;
		for j=1:numMovie
			
			if ratings(i,j) ~= 0
				
				acc = acc + (ratings(i,j)-meanUser(i))^2;
				count = count +1;
				
			end
			
		end
		
		VarUser(i) = acc/count;
		
	end
	
	
	%VarUser = sum(tempRatings,2) ./numRatingUser - meanUser.^2;
	
	
	
	stdUser = sqrt(VarUser);
	
	origRatings = ratings;
	
% 	for i = 1:numUser
% 		
% 		ratings(i,:) = (ratings(i,:)-meanUser(i)) / stdUser(i);
% 		
% 	end
% 	
	
	%initialize Variables
	
	%numUser = 500;
	%nuMovie = 1000;
	
	
	Q = rand(numUser, numMovie, numLatentClass);
	
	%D = sum(sum(sum(Q)));
	
	%Q = Q/D;
	
	A = rand(numUser, numLatentClass);
	
	B = sum(A,2);
	
	C = ones(1,numLatentClass);
	
	D = B * C;
	
	Pzu = A ./ D;
	
	M_yz = rand(numMovie, numLatentClass)*5;
	
	Std_yz = 3*rand(numMovie, numLatentClass)+1;
	
	%h=waitbar(0,'Please wait..');
	
	
	
	for countIter=1:numIteration
		
		%calculateE;
		
		%	    waitbar(i/numIteration);
		
		PreviousQ = Q;
		
		
		for countUser=1:numUser
			
			for countItem=1:numMovie
				
				down = 0;
				
				if origRatings(countUser,countItem) ~= 0
					
					up = Pzu(countUser,:) .* gaussianPDF(ratings(countUser,countItem)*ones(1,numLatentClass),M_yz(countItem,:),Std_yz(countItem,:));
					
					up = up.^beta;
					
					down = sum(up);
					
					if ismember(1,isnan(up/down))
						
						disp 'Q2 Nan occured'
						pause;
						
					end
					
					
					Q(countUser,countItem,:) = up/down;
					
					
					
				end
				
				
				
			end
			
			
		end
		
		
		
		if ismember(1,isnan(Q))
			
			disp 'Q NaN occured'
			
			pause;
			
		end
		
		disp([num2str(countIter), ' : Finished E step']);
		
		%calculate M
		
		%First Calculate M_yz
		
		PreviousM = M_yz;
		
		for countItem=1:numMovie
			
			for countLC=1:numLatentClass
				
				up = 0;
				
				down = 0;
				
				for countUser = 1 : numUser
					
					
					if origRatings(countUser,countItem) ~= 0
						
						up = up + ratings(countUser,countItem)*Q(countUser,countItem,countLC);
						
						down = down + Q(countUser,countItem,countLC);
						
					end
					
					
				end
				
				if (down ~=0)
					M_yz(countItem,countLC) = up/down;
				end
				
				
			end
			
		end
		
		
		if ismember(1,isnan(M_yz))
			
			disp 'M NaN occured'
			
			pause;
			
		end
		
		disp([num2str(countIter), ' : Updated Mean(yz)']);
		
		%Second Calculate Std_yz
		
		PreviousStd = Std_yz;
		
		for countItem=1:numMovie
			
			for countLC=1:numLatentClass
				
				tempup = 0;
				down = 0;
				
				for countUser = 1 : numUser
					
					if origRatings(countUser,countItem) ~= 0
						
						tempup = tempup + (ratings(countUser,countItem)-M_yz(countItem,countLC))^2*Q(countUser,countItem,countLC);
						
						down = down +  Q(countUser,countItem,countLC);
					end
					
				end
				
				
				
				if(tempup/down > 0.1)
					
					Std_yz(countItem,countLC) = sqrt(tempup/down);
					
				else
					
					Std_yz(countItem,countLC) = 0.1;
					
				end
				
			end
			
		end
		
		if ismember(1,isnan(Std_yz))
			
			disp 'Std NaN occured'
			
			pause;
			
		end
		
		disp([num2str(countIter), ' : Updated STD(yz)']);
		%Lastly Calculate Pzu
		
		PreviousPzu = Pzu;
		
		for countUser=1:numUser
			
			down=0;
			
			for countLC=1:numLatentClass
				
				
				up = 0;
				
				
				for countItem = 1 : numMovie
					
					up = up + Q(countUser,countItem,countLC);
					down = down + Q(countUser,countItem,countLC);
					
				end
				
				Pzu(countUser,countLC) = up;
				
				
			end
			
			
			
			Pzu(countUser,:) = Pzu(countUser,:) / down;
			
		end
		
		if ismember(1,isnan(Pzu))
			
			disp 'Pzu NaN occured'
			
			pause;
			
		end
		
		
		disp([num2str(countIter), ' : Updated P(yz)']);
		
		%disp(i);
		
		%calculateM;
		%displayRisk;
		
		numRating = 0;
		
		ExpectedRating = zeros(numUser,numMovie);
		
		for countUser=1:numUser
			
			for countItem=1:numMovie
				
				acc = 0;
				
				for countLC = 1:numLatentClass
					
					acc = acc + Pzu(countUser,countLC)*M_yz(countItem, countLC);
					
				end
				
				ExpectedRating(countUser,countItem) = acc;
				
				
			end
			
		end
		
		squareLoss = 0;
		
		for countUser=1:numUser
			
			for countItem=1:numMovie
				
				if origRatings(countUser, countItem) ~= 0
					
					
					numRating = numRating + 1;
					
					
					squareLoss = squareLoss +  (ratings(countUser,countItem)-ExpectedRating(countUser,countItem))^2;
					
				end
				
			end
			
		end
		
		for i =1:numUser
			
			NorExpRating(i,:) = ExpectedRating(i,:)*stdUser(i) + meanUser(i);
			
		end
		
		realSquareLoss = 0;
		
		for countUser=1:numUser
			
			for countItem=1:numMovie
				
				if origRatings(countUser, countItem) ~= 0
					
					realSquareLoss = realSquareLoss +  (origRatings(countUser,countItem)-NorExpRating(countUser,countItem))^2;
					
				end
				
			end
			
		end
		
		squareLoss = squareLoss/numRating
		
		realSquareLoss = realSquareLoss/numRating
		
		Risk(countIter)=squareLoss;
		
		plot(Risk),title(filename);
		
		drawnow;
		
		if countIter > 5
			
			if  abs(Risk(countIter-1) - Risk(countIter)) < Risk(countIter-1)*0.00000001
				
				disp 'Converged'
				
				break;
				
				
			end
			
		end
		
		
		
		
		disp([num2str(countIter), ' : Updated Risk)']);
		
		
	end
	
	filename = ['u',num2str(countFile),'.test'];
	
	M = dlmread(filename);
	
	[size, t] = size(M);
	
	testError = 0;
	
	for i=1:size 
		
		testError = testError + abs(NorExpRating(M(i,1),M(i,2))-M(i,3));
		
	end
	
	testError = testError/size
	
	
	fileName = ['Report',num2str(countFile),' at ', num2str(nowSet)];
	
	save(fileName);
	
	toc
	
end


