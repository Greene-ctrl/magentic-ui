# Use a Python base image
FROM python:3.12-bookworm

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PLAYWRIGHT_BROWSERS_PATH=/app/ms-playwright

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    rsync \
    gnupg \
    build-essential \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libcairo2 \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

# Install uv globally
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory
WORKDIR /app

# Optimize frontend build: Install dependencies first
COPY frontend/package.json frontend/yarn.lock ./frontend/
RUN cd frontend && yarn install

# Copy the rest of the application
COPY . .

# Build the frontend (this moves artifacts to src/magentic_ui/backend/web/ui)
RUN cd frontend && yarn build

# Install Python dependencies with uv
RUN uv pip install --system .

# Install Playwright and its browsers to a custom path
RUN mkdir -p /app/ms-playwright && \
    uv pip install --system playwright && \
    playwright install chromium

# Set up a new user named "user" with user ID 1000
RUN useradd -m -u 1000 user && \
    chown -R user:user /app
# Switch to the "user" user
USER user
# Set home for the user
ENV HOME=/home/user

# Expose the HF port
EXPOSE 7860

# Command to run the application
CMD ["magentic-ui", "--port", "7860", "--host", "0.0.0.0", "--run-without-docker"]
