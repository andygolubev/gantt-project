using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Npgsql;
using Dapper;
using System.Data;

public class Startup
{
    public IConfiguration Configuration { get; }

    public Startup(IConfiguration configuration)
    {
        Configuration = configuration;
    }

    public void ConfigureServices(IServiceCollection services)
    {
        services.AddControllers();

        // Use AddScoped instead of AddSingleton for IDbConnection
        services.AddScoped<IDbConnection>(sp =>
        {
            var connection = new NpgsqlConnection(Configuration.GetConnectionString("DefaultConnection"));
            connection.Open(); // Optionally, open the connection immediately
            return connection;
        });
    }

    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
        if (env.IsDevelopment())
        {
            app.UseDeveloperExceptionPage();
        }

        app.UseRouting();

        app.UseEndpoints(endpoints =>
        {
            endpoints.MapGet("/", async context =>
            {
                await context.Response.WriteAsync("Healthy");
            });

            endpoints.MapGet("/read", async context =>
            {
                var connection = context.RequestServices.GetRequiredService<IDbConnection>();
                var sql = @"SELECT 
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
                        LIMIT 50;";
                
                var result = await connection.QueryAsync(sql);
                await context.Response.WriteAsJsonAsync(result);
            });

            endpoints.MapPost("/write", async context =>
            {
                var connection = context.RequestServices.GetRequiredService<IDbConnection>();
                
                var sql = @"
                    WITH new_user AS (
                        INSERT INTO users (username, email) 
                        VALUES 
                        (
                            md5(random()::text || clock_timestamp()::text)::uuid::text,  -- UUID-like username
                            md5(random()::text || clock_timestamp()::text)::uuid::text || '@example.com'  -- UUID-like email
                        )
                        RETURNING id AS user_id
                    ),
                    -- Insert a new post for the created user and get the generated post id
                    new_post AS (
                        INSERT INTO posts (user_id, title, content)
                        SELECT user_id, 
                            'Post Title ' || trunc(random() * 100)::text, 
                            'This is a randomly generated post content.'
                        FROM new_user
                        RETURNING id AS post_id, user_id
                    )
                    -- Insert 100 random comments for the created post and user
                    INSERT INTO comments (post_id, user_id, comment_text)
                    SELECT new_post.post_id, 
                        new_post.user_id, 
                        'This is a random comment number ' || s.i || ' with random data ' || trunc(random() * 1000)::text
                    FROM generate_series(1, 100) AS s(i), new_post;";

                try
                {
                    var result = await connection.ExecuteAsync(sql);
                    await context.Response.WriteAsync("Data Inserted Successfully");
                }
                catch (Exception ex)
                {
                    context.Response.StatusCode = 500; // Internal Server Error
                    await context.Response.WriteAsync($"An error occurred: {ex.Message}");
                }
            });

            endpoints.MapPost("/create-schema", async context =>
            {
                var connection = context.RequestServices.GetRequiredService<IDbConnection>();

                var sql = @"
                    -- Create the users table
                    CREATE TABLE IF NOT EXISTS users (
                        id SERIAL PRIMARY KEY,
                        username VARCHAR(50) UNIQUE NOT NULL,
                        email VARCHAR(100) UNIQUE NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );

                    -- Create the posts table
                    CREATE TABLE IF NOT EXISTS posts (
                        id SERIAL PRIMARY KEY,
                        user_id INT REFERENCES users(id) ON DELETE CASCADE,
                        title VARCHAR(200) NOT NULL,
                        content TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );

                    -- Create the comments table
                    CREATE TABLE IF NOT EXISTS comments (
                        id SERIAL PRIMARY KEY,
                        post_id INT REFERENCES posts(id) ON DELETE CASCADE,
                        user_id INT REFERENCES users(id) ON DELETE CASCADE,
                        comment_text TEXT NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );

                    -- Create indexes to improve performance
                    CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
                    CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
                    CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
                    CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
                ";

                try
                {
                    await connection.ExecuteAsync(sql);
                    await context.Response.WriteAsync("Database and tables created successfully.");
                }
                catch (Exception ex)
                {
                    context.Response.StatusCode = 500; // Internal Server Error
                    await context.Response.WriteAsync($"An error occurred: {ex.Message}");
                }
            });
        
        });
    }
}
