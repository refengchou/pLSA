tic 
close all

clear

%============================
% Custom input Parameters
%============================

q = 1;

numIteration = 200;

numLatentClass = 40; 

beta = 1


load 1Kratings

[numUser numMovie] = size(ratings);

meanUser = mean(ratings,2);

edges = [ 0 1 2 3 4 5];

n=histc(ratings,edges,2);

numRatingUser = n(:,2)+n(:,3)+n(:,4) + n(:,5) + n(:,6);

meanUser = sum(ratings,2) ./ numRatingUser;
% 
% stdAll = std2(ratings);
% 
% VarUser = (var(ratings,0,2) + q*stdAll) ./ (numRatingUser + q);
% stdUser = sqrt(VarUser);

VarUser = 0;

tempRatings = ratings.^2;

VarUser = sum(tempRatings,2) ./numRatingUser - meanUser.^2;



stdUser = sqrt(VarUser);

origRatings = ratings;

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
			
			if ismember(1,isnan(up/down))
				
				disp 'Q2 Nan occured'
				
			end
			
				
			Q(countUser,countItem,:) = up/down;
			
				
		end
		
		
	end
	
	 
D = sum(sum(sum(Q)));

Q = Q/D;

	if ismember(1,isnan(Q)) 
		
		disp 'Q NaN occured'
		
		%pause;
		
	end
	
	disp([num2str(i), ' : Finished E step']);
		
	%calculate M
	
	%First Calculate M_yz
	
	PreviousM = M_yz; 
	
	for countItem=1:numMovie
		
		for countLC=1:numLatentClass

			up = 0; 

			for countUser = 1 : numUser

				if origRatings(countUser,countItem) ~= 0
				
					up = up + ratings(countUser,countItem)*Q(countUser,countItem,countLC);
				
				end

			end
			
			down = sum(Q(:,countItem,countLC));

			M_yz(countItem,countLC) = up/down;

		end
		
	end
	
	
	if ismember(1,isnan(M_yz)) 
		
		disp 'M NaN occured'
		
		pause;
		
	end
	
	disp([num2str(i), ' : Updated Mean(yz)']);
	
	%Second Calculate Std_yz
	
	PreviousStd = Std_yz;
	
	for countItem=1:numMovie
		
		for countLC=1:numLatentClass

			tempup = 0; 

			for countUser = 1 : numUser

				if origRatings(countUser,countItem) ~= 0
				
					tempup = tempup + (ratings(countUser,countItem)-M_yz(countItem,countLC))^2*Q(countUser,countItem,countLC);
					
				end
			end
			
			down = sum(Q(:,countItem,countLC));
			
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
		
		
	
		Pzu(countUser,:) = Pzu(countUser,:) / down;
	
	end
	
	if ismember(1,isnan(Pzu)) 
		
		disp 'Pzu NaN occured'
		
		pause;
		
	end

	
	disp([num2str(i), ' : Updated P(yz)']);
	
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

