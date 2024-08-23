SELECT 
    users.id AS user_id,
    users.username,
    users.email,
    COALESCE(post_count, 0) AS total_posts,
    COALESCE(comment_count, 0) AS total_comments,
    COALESCE(post_count, 0) + COALESCE(comment_count, 0) AS total_activity
FROM 
    users
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS post_count FROM posts GROUP BY user_id) AS user_posts
    ON users.id = user_posts.user_id
LEFT JOIN 
    (SELECT user_id, COUNT(*) AS comment_count FROM comments GROUP BY user_id) AS user_comments
    ON users.id = user_comments.user_id
ORDER BY 
    total_activity DESC
LIMIT 50;