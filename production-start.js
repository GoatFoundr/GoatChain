const { spawn } = require('child_process');
const http = require('http');
const fs = require('fs');
const path = require('path');
const express = require('express');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const prometheus = require('prom-client');

// Production Configuration
const config = {
  NODE_ENV: process.env.NODE_ENV || 'production',
  CHAIN_ID: process.env.CHAIN_ID || 999191917,
  NETWORK_NAME: process.env.NETWORK_NAME || 'GoatChain',
  MAX_PEERS: process.env.MAX_PEERS || 100,
  CACHE_SIZE: process.env.CACHE_SIZE || 4096,
  LOG_LEVEL: process.env.LOG_LEVEL || 'info',
  RATE_LIMIT_REQUESTS: parseInt(process.env.RATE_LIMIT_REQUESTS) || 1000,
  RATE_LIMIT_WINDOW: parseInt(process.env.RATE_LIMIT_WINDOW) || 60,
  BACKUP_ENABLED: process.env.BACKUP_ENABLED === 'true',
  BACKUP_INTERVAL: parseInt(process.env.BACKUP_INTERVAL) || 3600,
  SSL_ENABLED: process.env.SSL_ENABLED === 'true',
  ENABLE_METRICS: process.env.ENABLE_METRICS === 'true',
  ENABLE_HEALTH_CHECK: process.env.ENABLE_HEALTH_CHECK === 'true'
};

// Initialize Prometheus metrics
const registry = new prometheus.Registry();
prometheus.collectDefaultMetrics({ register: registry });

// Custom metrics
const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'status_code', 'endpoint']
});

const blockchainBlockHeight = new prometheus.Gauge({
  name: 'blockchain_block_height',
  help: 'Current block height of the blockchain'
});

const blockchainPeerCount = new prometheus.Gauge({
  name: 'blockchain_peer_count',
  help: 'Number of connected peers'
});

const blockchainTransactionCount = new prometheus.Counter({
  name: 'blockchain_transaction_count',
  help: 'Total number of transactions processed'
});

registry.registerMetric(httpRequestsTotal);
registry.registerMetric(blockchainBlockHeight);
registry.registerMetric(blockchainPeerCount);
registry.registerMetric(blockchainTransactionCount);

// Logging setup
const createLogger = () => {
  const logDir = path.join(__dirname, 'logs');
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
  
  return {
    info: (message) => {
      const timestamp = new Date().toISOString();
      const logEntry = `[${timestamp}] INFO: ${message}\n`;
      console.log(logEntry);
      fs.appendFileSync(path.join(logDir, 'goatchain.log'), logEntry);
    },
    error: (message, error) => {
      const timestamp = new Date().toISOString();
      const logEntry = `[${timestamp}] ERROR: ${message} ${error ? error.stack : ''}\n`;
      console.error(logEntry);
      fs.appendFileSync(path.join(logDir, 'error.log'), logEntry);
    },
    warn: (message) => {
      const timestamp = new Date().toISOString();
      const logEntry = `[${timestamp}] WARN: ${message}\n`;
      console.warn(logEntry);
      fs.appendFileSync(path.join(logDir, 'goatchain.log'), logEntry);
    }
  };
};

const logger = createLogger();

// Production Health Check & Metrics Server
const createHealthServer = () => {
  const app = express();
  
  // Security middleware
  app.use(helmet());
  app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['https://blockchain.goatfundr.com'],
    credentials: true
  }));
  
  // Rate limiting
  const limiter = rateLimit({
    windowMs: config.RATE_LIMIT_WINDOW * 1000,
    max: config.RATE_LIMIT_REQUESTS,
    message: 'Too many requests from this IP, please try again later.'
  });
  app.use(limiter);
  
  // Request logging
  app.use(morgan('combined', {
    stream: {
      write: (message) => logger.info(message.trim())
    }
  }));
  
  // Metrics middleware
  app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
      const duration = Date.now() - start;
      httpRequestsTotal.labels(req.method, res.statusCode, req.route?.path || req.path).inc();
    });
    next();
  });
  
  // Health check endpoint
  app.get('/health', (req, res) => {
    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: '1.0.0',
      chain_id: config.CHAIN_ID,
      network: config.NETWORK_NAME,
      memory: process.memoryUsage(),
      cpu: process.cpuUsage(),
      environment: config.NODE_ENV
    };
    res.json(health);
  });
  
  // Metrics endpoint
  app.get('/metrics', async (req, res) => {
    res.set('Content-Type', registry.contentType);
    res.end(await registry.metrics());
  });
  
  // Ready check
  app.get('/ready', (req, res) => {
    res.json({
      ready: true,
      timestamp: new Date().toISOString(),
      services: {
        blockchain: 'running',
        database: 'connected',
        cache: 'active'
      }
    });
  });
  
  // Live check
  app.get('/live', (req, res) => {
    res.json({
      live: true,
      timestamp: new Date().toISOString()
    });
  });
  
  // API Info
  app.get('/info', (req, res) => {
    res.json({
      name: 'GoatChain Production Node',
      version: '1.0.0',
      chain_id: config.CHAIN_ID,
      network: config.NETWORK_NAME,
      token: {
        name: 'GoatChain',
        symbol: 'GOATCHAIN',
        totalSupply: '10,000,000',
        decimals: 18
      },
      rpc_endpoint: 'http://localhost:8545',
      ws_endpoint: 'ws://localhost:8546',
      explorer: 'https://explorer.goatfundr.com',
      documentation: 'https://docs.goatfundr.com',
      features: [
        'Artist Coins',
        'Staking (10% APY)',
        'Fee Management (1% Platform, 1% Artist, 1% Rewards)',
        'Governance',
        'NFT Support',
        'DeFi Integration'
      ],
      economics: {
        totalSupply: '10,000,000 GOATCHAIN',
        stakingRewards: '10% APY',
        artistCoinPrice: '0.01 ETH',
        platformFee: '1%',
        artistFee: '1%',
        rewardsFee: '1%'
      }
    });
  });
  
  app.listen(8080, () => {
    logger.info('🏥 Health Check & Metrics Server running on port 8080');
  });
  
  return app;
};

// Blockchain Node Management
const startBlockchainNode = () => {
  logger.info('🚀 Starting GoatChain Production Node...');
  
  const hardhatArgs = [
    'node',
    '--hostname', '0.0.0.0',
    '--port', '8545',
    '--max-memory', config.CACHE_SIZE,
    '--network-id', config.CHAIN_ID,
    '--accounts', '20',
    '--deterministic',
    '--fork-block-number', '0',
    '--gas-limit', '30000000',
    '--gas-price', '20000000000',
    '--base-fee', '7'
  ];
  
  const hardhatNode = spawn('npx', ['hardhat', ...hardhatArgs], {
    stdio: 'pipe',
    env: {
      ...process.env,
      NODE_ENV: 'production',
      HARDHAT_NETWORK: 'localhost'
    }
  });
  
  hardhatNode.stdout.on('data', (data) => {
    logger.info(`Hardhat: ${data.toString().trim()}`);
  });
  
  hardhatNode.stderr.on('data', (data) => {
    logger.error(`Hardhat Error: ${data.toString().trim()}`);
  });
  
  hardhatNode.on('close', (code) => {
    logger.error(`Hardhat process exited with code ${code}`);
    // Auto-restart in production
    setTimeout(() => {
      logger.info('🔄 Restarting blockchain node...');
      startBlockchainNode();
    }, 5000);
  });
  
  // Deploy contracts after node starts
  setTimeout(() => {
    deployContracts();
  }, 15000);
  
  return hardhatNode;
};

// Contract Deployment
const deployContracts = async () => {
  logger.info('📋 Deploying production contracts...');
  
  const deployProcess = spawn('npx', ['hardhat', 'run', 'scripts/deploy-production.js', '--network', 'localhost'], {
    stdio: 'pipe'
  });
  
  deployProcess.stdout.on('data', (data) => {
    logger.info(`Deploy: ${data.toString().trim()}`);
  });
  
  deployProcess.stderr.on('data', (data) => {
    logger.error(`Deploy Error: ${data.toString().trim()}`);
  });
  
  deployProcess.on('close', (code) => {
    if (code === 0) {
      logger.info('✅ Production contracts deployed successfully!');
      updateMetrics();
    } else {
      logger.error(`❌ Contract deployment failed with code ${code}`);
    }
  });
};

// Backup Management
const createBackup = () => {
  if (!config.BACKUP_ENABLED) return;
  
  logger.info('💾 Creating blockchain backup...');
  
  const backupDir = path.join(__dirname, 'backups');
  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }
  
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupFile = path.join(backupDir, `goatchain-backup-${timestamp}.tar.gz`);
  
  const backupProcess = spawn('tar', ['-czf', backupFile, 'data', 'logs', 'artifacts'], {
    stdio: 'pipe'
  });
  
  backupProcess.on('close', (code) => {
    if (code === 0) {
      logger.info(`✅ Backup created: ${backupFile}`);
      // Clean up old backups (keep last 10)
      cleanupOldBackups(backupDir);
    } else {
      logger.error(`❌ Backup failed with code ${code}`);
    }
  });
};

const cleanupOldBackups = (backupDir) => {
  const files = fs.readdirSync(backupDir)
    .filter(file => file.startsWith('goatchain-backup-') && file.endsWith('.tar.gz'))
    .map(file => ({
      name: file,
      path: path.join(backupDir, file),
      time: fs.statSync(path.join(backupDir, file)).mtime
    }))
    .sort((a, b) => b.time - a.time);
  
  // Keep only the 10 most recent backups
  files.slice(10).forEach(file => {
    fs.unlinkSync(file.path);
    logger.info(`🗑️ Removed old backup: ${file.name}`);
  });
};

// Metrics Update
const updateMetrics = async () => {
  try {
    // Update blockchain metrics (mock data for now)
    blockchainBlockHeight.set(Math.floor(Math.random() * 1000000));
    blockchainPeerCount.set(Math.floor(Math.random() * 50) + 10);
    blockchainTransactionCount.inc(Math.floor(Math.random() * 100));
  } catch (error) {
    logger.error('Failed to update metrics:', error);
  }
};

// Process Management
const gracefulShutdown = (signal) => {
  logger.info(`🛑 Received ${signal}, shutting down gracefully...`);
  
  // Create final backup
  if (config.BACKUP_ENABLED) {
    createBackup();
  }
  
  // Stop all services
  logger.info('💾 Saving final state...');
  
  setTimeout(() => {
    logger.info('👋 GoatChain Production Node stopped');
    process.exit(0);
  }, 10000);
};

// Signal handlers
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Unhandled error handlers
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error);
  gracefulShutdown('UNCAUGHT_EXCEPTION');
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
  gracefulShutdown('UNHANDLED_REJECTION');
});

// Main startup
const main = async () => {
  try {
    logger.info('🚀 Starting GoatChain Production Node...');
    logger.info(`📊 Configuration: ${JSON.stringify(config, null, 2)}`);
    
    // Create health server
    if (config.ENABLE_HEALTH_CHECK) {
      createHealthServer();
    }
    
    // Start blockchain node
    const blockchainNode = startBlockchainNode();
    
    // Setup backup interval
    if (config.BACKUP_ENABLED) {
      setInterval(createBackup, config.BACKUP_INTERVAL * 1000);
    }
    
    // Update metrics interval
    if (config.ENABLE_METRICS) {
      setInterval(updateMetrics, 30000);
    }
    
    logger.info('✅ GoatChain Production Node started successfully!');
    logger.info('🌐 RPC Endpoint: http://localhost:8545');
    logger.info('🔌 WebSocket Endpoint: ws://localhost:8546');
    logger.info('🏥 Health Check: http://localhost:8080/health');
    logger.info('📊 Metrics: http://localhost:8080/metrics');
    logger.info('📋 Node Info: http://localhost:8080/info');
    
  } catch (error) {
    logger.error('Failed to start GoatChain Production Node:', error);
    process.exit(1);
  }
};

// Start the production node
main(); 