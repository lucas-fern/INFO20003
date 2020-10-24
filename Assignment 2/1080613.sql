-- __/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\_____/\\\\\_________/\\\\\\\\\_________/\\\\\\\________/\\\\\\\________/\\\\\\\________/\\\\\\\\\\________________/\\\\\\\\\_______/\\\\\\\\\_____        
--  _\/////\\\///__\/\\\\\\___\/\\\_\/\\\///////////____/\\\///\\\_____/\\\///////\\\_____/\\\/////\\\____/\\\/////\\\____/\\\/////\\\____/\\\///////\\\_____________/\\\\\\\\\\\\\___/\\\///////\\\___       
--   _____\/\\\_____\/\\\/\\\__\/\\\_\/\\\_____________/\\\/__\///\\\__\///______\//\\\___/\\\____\//\\\__/\\\____\//\\\__/\\\____\//\\\__\///______/\\\_____________/\\\/////////\\\_\///______\//\\\__      
--    _____\/\\\_____\/\\\//\\\_\/\\\_\/\\\\\\\\\\\____/\\\______\//\\\___________/\\\/___\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\_________/\\\//_____________\/\\\_______\/\\\___________/\\\/___     
--     _____\/\\\_____\/\\\\//\\\\/\\\_\/\\\///////____\/\\\_______\/\\\________/\\\//_____\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\________\////\\\____________\/\\\\\\\\\\\\\\\________/\\\//_____    
--      _____\/\\\_____\/\\\_\//\\\/\\\_\/\\\___________\//\\\______/\\\______/\\\//________\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\___________\//\\\___________\/\\\/////////\\\_____/\\\//________   
--       _____\/\\\_____\/\\\__\//\\\\\\_\/\\\____________\///\\\__/\\\______/\\\/___________\//\\\____/\\\__\//\\\____/\\\__\//\\\____/\\\___/\\\______/\\\____________\/\\\_______\/\\\___/\\\/___________  
--        __/\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\______________\///\\\\\/______/\\\\\\\\\\\\\\\__\///\\\\\\\/____\///\\\\\\\/____\///\\\\\\\/___\///\\\\\\\\\/_____________\/\\\_______\/\\\__/\\\\\\\\\\\\\\\_ 
--         _\///////////__\///_____\/////__\///_________________\/////_______\///////////////_____\///////________\///////________\///////_______\/////////_______________\///________\///__\///////////////__

-- Your Name: Lucas Fern
-- Your Student Number: 1080613
-- By submitting, you declare that this work was completed entirely by yourself.

-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q1

SELECT Id, Topic, CreatedBy AS Lecturer 
FROM forum
WHERE CreatedBy = ClosedBy;

-- END Q1
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q2

SELECT lecturer.Id, CONCAT(user.Firstname, ' ', user.Lastname) AS Name, COUNT(forum.Id) AS 'Number of Forums'
FROM lecturer 
	NATURAL JOIN user
	LEFT JOIN forum ON lecturer.Id = forum.CreatedBy
GROUP BY lecturer.Id;

-- END Q2
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q3

SELECT Id, Username
FROM user
WHERE Id NOT IN (
	SELECT PostedBy 
	FROM post
	WHERE ParentPost IS NULL
);

-- END Q3
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q4

SELECT Id AS postID
FROM (
	SELECT post.Id, post.Content, post.ParentPost, COUNT(likepost.WhenLiked)
	FROM post 
		LEFT JOIN likepost ON post.Id = likepost.Post
	GROUP BY post.Id
	HAVING COUNT(likepost.WhenLiked) = 0 AND post.ParentPost IS NULL
		AND post.Id NOT IN (
			SELECT DISTINCT ParentPost
            FROM post
            WHERE ParentPost IS NOT NULL
		)
) AS unreactedPosts;

-- END Q4
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q5

SELECT likepost.Post, post.Content, COUNT(likepost.WhenLiked) AS numLikes
FROM likepost 
	INNER JOIN post ON likepost.Post = post.Id
GROUP BY Post
HAVING numLikes = ( -- Find the maximum amount of likes
				    -- This solution is jank, I see why you had to tell us not to disable full_group_by...
	SELECT MAX(numLikes)
	FROM (
		SELECT Post, COUNT(WhenLiked) AS numLikes
		FROM likepost
		GROUP BY Post
	) AS likecount
);

-- END Q5
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q6

SELECT LENGTH(post.Content) AS contentLen, post.Content, forum.Topic, CONCAT(user.Firstname, ' ', user.Lastname) AS 'Full Name'
FROM post 
	INNER JOIN user ON post.PostedBy = user.Id
	INNER JOIN forum ON post.Forum = forum.Id
HAVING contentLen = (
	SELECT MAX(LENGTH(Content))
	FROM post
);

-- END Q6
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q7

-- Solution that DOES display the amount of days (and fractional days) that they remained friends

SELECT Student1, Student2, TIMESTAMPDIFF(MICROSECOND, WhenConfirmed, WhenUnfriended) / 86400000000 AS friendTime  -- There are 86,400,000,000 microseconds in a day
																												  -- we are using microseconds to be confident we have the shortest friendship
																												  -- with as much accuracy as possible.
FROM friendof
HAVING friendTime * 86400000000 = (
	SELECT MIN(TIMESTAMPDIFF(MICROSECOND, WhenConfirmed, WhenUnfriended))
	FROM friendof
);

-- Below is a solution that does not show the amount of days (student1ID, student2ID)

-- SELECT Student1, Student2 
-- FROM (
-- 	SELECT Student1, Student2, TIMESTAMPDIFF(MICROSECOND, WhenConfirmed, WhenUnfriended) AS friendTime
-- 	FROM friendof
-- 	HAVING friendTime = (
-- 		SELECT MIN(TIMESTAMPDIFF(MICROSECOND, WhenConfirmed, WhenUnfriended))
-- 		FROM friendof
-- 	)
-- ) AS shortFriends;

-- END Q7
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q8

SELECT likepost.User, (likeCounts.likeCount - 1) AS otherLikeCount, likepost.Post
FROM likepost 
	INNER JOIN user ON likepost.User = user.Id
    INNER JOIN (
		SELECT post.Id, COUNT(likepost.User) AS likeCount
		FROM likepost
			RIGHT OUTER JOIN post ON likepost.Post = post.Id
		GROUP BY post.Id
	) AS likeCounts ON likepost.Post = likeCounts.Id;

-- END Q8
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q9

SELECT student1.Id AS 'IDs of Friends of Most Popular Student'
FROM (
	SELECT Student1, Student2, WhenConfirmed, WhenUnfriended
	FROM friendof
	UNION
	SELECT Student2 AS Student1, Student1 AS Student2, WhenConfirmed, WhenUnfriended
	FROM friendof
) AS friendCombinaitons  -- A table containing A + B as a seperate friendship to B + A
	INNER JOIN student AS student1 ON friendCombinaitons.Student1 = student1.Id
	INNER JOIN student AS student2 ON friendCombinaitons.Student2 = student2.Id
WHERE student2.Id = (  -- Check that the second student is the most popular student so that we can just return the student on the other side of the friendship
	SELECT post.PostedBy
	FROM post
		INNER JOIN likepost ON post.Id = likepost.Post
		INNER JOIN student ON post.PostedBy = student.Id
	GROUP BY post.PostedBy
	-- Take only the user ID with the highest number of total likes.
	ORDER BY COUNT(likepost.User) DESC
	LIMIT 1
)
	AND student1.Degree = student2.Degree  -- Check that the degrees are the same
	AND friendCombinaitons.WhenConfirmed IS NOT NULL  -- And make sure the students are currently friends
	AND friendCombinaitons.WhenUnfriended IS NULL;
  
-- END Q9
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q10

SELECT Id, WhenPosted
FROM post
WHERE Forum IS NOT NULL
	AND PostedBy IN (
		SELECT Id
        FROM student
	)
    AND Id NOT IN (
		SELECT topLevel.Id  -- Find all the student's posts which DID recieve a reply from the lecturer within 48h
		FROM post AS topLevel
			LEFT OUTER JOIN post AS reply ON reply.ParentPost = topLevel.Id
			INNER JOIN forum ON topLevel.Forum = forum.Id
		WHERE topLevel.PostedBy IN (
				SELECT Id
				FROM student
			)
			AND forum.CreatedBy = reply.PostedBy
			AND TIMESTAMPDIFF(HOUR, topLevel.WhenPosted, reply.WhenPosted) < 48
	);

-- END Q10
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- END OF ASSIGNMENT Do not write below this line