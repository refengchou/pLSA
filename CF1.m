tic 
close all

clear

%============================
% Custom input Parameters
%============================

q = 5;

numIteration = 200;

numLatentClass = 5; 

beta = 0.5



%============================

if matlabpool('size') == 0 
	
	%matlabpool 

end

load smallRatings

colormap('bone');

[numUser numMovie] = size(ratings);

movieRatings = zeros(numMovie ,2);
userRatings = zeros (numUser,2);

count = 0;

TempRating = 0;

for i =1:numMovie 
	
	for j = 1:numUser 

		if ratings(j,i) > 0 
			
			count = count+1;
			
			TempRating = TempRating + ratings(j,i);
		end
		
	end
	
	
	movieRatings(i,1) = count;
	
	movieRatings(i,2) = TempRating/count;
	
	count =0;
	TempRating =0;
end

for i =1:numUser 
	
	for j = 1:numMovie 

		if ratings(i,j) > 0 
			
			count = count+1;
			
			TempRating = TempRating + ratings(i,j);
		end
		
	end
	
	
	userRatings(i,1) = count;
	
	userRatings(i,2) = TempRating/count;
	
	count =0;
	TempRating =0;
	
	
end

meanUser = mean(ratings,2);

edges = [ 0 1 2 3 4 5];

n=histc(ratings,edges,2);

numRatingUser = n(:,2)+n(:,3)+n(:,4) + n(:,5) + n(:,6);

stdAll = std2(ratings);

VarUser = (var(ratings,0,2) + q*stdAll) ./ (numRatingUser + q);
stdUser = sqrt(VarUser);

for i = 1:numUser
	
	ratings(i,:) = (ratings(i,:)-meanUser(i)) / stdUser(i);
	
end


%initialize Variables

%numUser = 500;
%nuMovie = 1000;


Q = rand(numUser, numMovie, numLatentClass);

D = sum(sum(sum(Q)));

Q = Q/D;

A = rand(numUser, numLatentClass);

B = sum(A,2);

C = ones(1,numLatentClass);

D = B * C;

Pzu = A ./ D;

M_yz = randn(numMovie, numLatentClass);

Std_yz = 3*rand(numMovie, numLatentClass)+1;

h=waitbar(0,'Please wait..');


    
for i=1:numIteration 
	
	%calculateE;
	
	    waitbar(i/numIteration);
		
	PreviousQ = Q;

	
	for countUser=1:numUser
		
		for countItem=1:numMovie
							
			down = 0;

			up = Pzu(countUser,:) .* gaussianPDF(ratings(countUser,countItem)*ones(1,numLatentClass),M_yz(countItem,:),Std_yz(countItem,:));
			
			up = up.^beta;
			
			down = sum(up);
			
			
	if ismember(1,isnan(up)) 
		
		disp 'UP NaN occured'
		
		pause;
		
	end
	
			if down ~= 0 
				
				Q(countUser,countItem,:) = up/down;
			else
			
				disp 'Q down is 0'
				pause;
			end
			
			
				
		end
		%disp(countUser);
		
	end
	
	temp = sum(sum(sum(Q)));
	
	Q = Q/temp;
	
	A = isnan(Q);
	
	if ismember(1,A) 
		
		disp 'Q NaN occured'
		
		pause;
		
	end
	
	
	
	disp([num2str(i), ' : Finished E step']);
		
	%calculate M
	
	%First Calculate M_yz
	
	PreviousM = M_yz; 
	
	for countItem=1:numMovie
		
		for countLC=1:numLatentClass

			up = 0; 
			down =0;

			for countUser = 1 : numUser

				if ratings(countUser,countItem) ~= 0
				
					up = up + ratings(countUser,countItem)*Q(countUser,countItem,countLC);
				
					down = down + Q(countUser,countItem,countLC);
					
				end
				

			end
			
			if isnan(up/down)
				
				disp 'M NaN occured!'
				
				pause;
				
			else 

				M_yz(countItem,countLC) = up/down;

			end

		end
		
	end
	
	
	if ismember(1,isnan(M_yz)) 
		
		disp 'M NaN occured'
		
		%pause;
		
	end
	
	disp([num2str(i), ' : Updated Mean(yz)']);
	%Second Calculate Std_yz
	
	PreviousStd = Std_yz;
	
	for countItem=1:numMovie
		
		for countLC=1:numLatentClass

			up = 0; 
			down =0;

			for countUser = 1 : numUser

				if ratings(countUser,countItem) ~= 0
				
					up = up + (ratings(countUser,countItem)-M_yz(countItem,countLC))^2*Q(countUser,countItem,countLC);
					down = down + Q(countUser,countItem,countLC);

				end
			end
			
			if isnan(up/down)
				
				disp 'STD NaN occured'
				
				pause
				
			else 

				Std_yz(countItem,countLC) = sqrt(up/down);

			end
						
		end
		
	end
	 
	if ismember(1,isnan(Std_yz)) 
		
		disp 'Std NaN occured'
		
		pause;
		
	end
	
	disp([num2str(i), ' : Updated STD(yz)']);
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
		
		
		if down == 0
			
			disp 'Pzu NaN occured'
			
			pause
			
		else 	
	
			Pzu(countUser,:) = Pzu(countUser,:) / down;

		end
		
	end
	
	if ismember(1,isnan(Pzu)) 
		
		disp 'Pzu NaN occured'
		
		%pause;
		
	end

	
	disp([num2str(i), ' : Updated P(yz)']);
	
	%disp(i);
	
	%calculateM;
	%displayRisk;

	numRating = 0;
	
	ExpectedRating = zeros(numUser,numMovie);
	
	for countUser=1:numUser
		
		for countItem=1:numMovie
			
			if ratings(countUser, countItem) ~= 0 
				
				numRating = numRating + 1;
				acc = 0;
				
				for countLC = 1:numLatentClass
					
					acc = acc + Pzu(countUser,countLC)*M_yz(countItem, countLC);
					
				end
				
				ExpectedRating(countUser,countItem) = acc;
				
			end
			
		end
		
	end
	
	squareLoss = 0;
	
	for countUser=1:numUser
		
		for countItem=1:numMovie
			
			if ratings(countUser, countItem) ~= 0 
				
				squareLoss = squareLoss +  sqrt((ratings(countUser,countItem)-ExpectedRating(countUser,countItem))^2);
				
			end
			
		end
		
	end
	
	squareLoss = squareLoss/numRating
	
	Risk(i)=squareLoss;
	
	plot(Risk);
	
	
	disp([num2str(i), ' : Updated Risk)']);
		
		
end


close(h)

toc

