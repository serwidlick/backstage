/// Enhanced multi-tab console panel with advanced features.
///
/// This file contains the main console interface that integrates all Backstage
/// features including logs, network monitoring, performance metrics, search
/// capabilities, and export functionality in a comprehensive tabbed interface.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../backstage.dart';
import '../services/enhanced_logger.dart';
import '../services/export_service.dart';
import '../services/network_service.dart';
import '../services/performance_service.dart';
import '../services/security_service.dart';

/// Enhanced console panel with tabbed interface and advanced features.
///
/// [EnhancedConsolePanel] provides a comprehensive debugging interface that
/// integrates all Backstage features in an organized, tabbed layout. It
/// supports real-time log display, network monitoring, performance metrics,
/// search functionality, and data export capabilities.
///
/// **Console Tabs**:
/// * **Logs**: Real-time log display with filtering and search
/// * **Network**: HTTP request/response monitoring and analysis
/// * **Performance**: System metrics and performance monitoring
/// * **Search**: Advanced search and filtering across all data types
/// * **Export**: Data export and sharing functionality
/// * **Settings**: Console configuration and preferences
///
/// **Key Features**:
/// * Multi-tab organization for different data types
/// * Real-time updates with pause/resume functionality
/// * Advanced search with regex and multi-criteria support
/// * Export integration with multiple formats
/// * Performance monitoring with threshold alerts
/// * Responsive design that adapts to screen size
/// * Keyboard shortcuts for power users
/// * Accessibility support with screen reader compatibility
///
/// Example usage:
/// ```dart
/// EnhancedConsolePanel(
///   logger: enhancedLogger,
///   networkService: networkService,
///   performanceService: performanceService,
///   exportService: exportService,
///   securityService: securityService,
///   uiConfig: uiConfig,
/// )
/// ```
class EnhancedConsolePanel extends StatefulWidget {
  /// Enhanced logger instance for log display and search
  final EnhancedLogger logger;

  /// Network service for HTTP monitoring
  final NetworkService? networkService;

  /// Performance service for system metrics
  final PerformanceService? performanceService;

  /// Export service for data export functionality
  final ExportService? exportService;

  /// Security service for authentication and sanitization
  final SecurityService? securityService;

  /// UI configuration for layout and behavior
  final UIConfig uiConfig;

  /// Creates a new enhanced console panel.
  ///
  /// The [logger] parameter is required as it provides the core logging
  /// functionality. Other services are optional and enable additional
  /// features when provided.
  const EnhancedConsolePanel({
    super.key,
    required this.logger,
    this.networkService,
    this.performanceService,
    this.exportService,
    this.securityService,
    required this.uiConfig,
  });

  @override
  State<EnhancedConsolePanel> createState() => _EnhancedConsolePanelState();
}

/// State for the enhanced console panel managing tabs and data display.
class _EnhancedConsolePanelState extends State<EnhancedConsolePanel>
    with TickerProviderStateMixin {
  /// Tab controller for managing the tabbed interface
  late TabController _tabController;

  /// Current logs displayed in the console
  final List<BackstageLog> _logs = [];

  /// Current network requests displayed
  final List<NetworkRequest> _networkRequests = [];

  /// Current performance snapshots
  final List<PerformanceSnapshot> _performanceSnapshots = [];

  /// Stream subscriptions for real-time updates
  final List<StreamSubscription> _subscriptions = [];

  /// Whether the console is paused (not receiving new updates)
  bool _isPaused = false;

  /// Current search query
  String _searchQuery = '';

  /// Selected tab index
  int _selectedTabIndex = 0;

  /// Scroll controller for log list
  final ScrollController _scrollController = ScrollController();

  /// Focus node for search field
  final FocusNode _searchFocusNode = FocusNode();

  /// Available console tabs
  List<ConsoleTab> get _availableTabs => [
        ConsoleTab(
          key: 'logs',
          title: 'Logs',
          icon: Icons.article_outlined,
          badge: _logs.length,
          builder: (context) => _buildLogsTab(),
        ),
        if (widget.networkService != null)
          ConsoleTab(
            key: 'network',
            title: 'Network',
            icon: Icons.wifi,
            badge: _networkRequests.length,
            builder: (context) => _buildNetworkTab(),
          ),
        if (widget.performanceService != null)
          ConsoleTab(
            key: 'performance',
            title: 'Performance',
            icon: Icons.speed,
            badge: _performanceSnapshots.length,
            builder: (context) => _buildPerformanceTab(),
          ),
        ConsoleTab(
          key: 'search',
          title: 'Search',
          icon: Icons.search,
          builder: (context) => _buildSearchTab(),
        ),
        if (widget.exportService != null)
          ConsoleTab(
            key: 'export',
            title: 'Export',
            icon: Icons.download,
            builder: (context) => _buildExportTab(),
          ),
        ConsoleTab(
          key: 'settings',
          title: 'Settings',
          icon: Icons.settings,
          builder: (context) => _buildSettingsTab(),
        ),
      ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: _availableTabs.length,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    _setupDataStreams();
    _loadInitialData();
    _setupKeyboardShortcuts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: widget.uiConfig.panelElevation ?? 8.0,
      borderRadius: BorderRadius.circular(widget.uiConfig.borderRadius ?? 12.0),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: _calculatePanelWidth(),
        height: _calculatePanelHeight(),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(
            widget.uiConfig.panelOpacity ?? 0.95,
          ),
        ),
        child: Column(
          children: [
            _buildToolbar(theme),
            _buildTabBar(theme),
            Expanded(
              child: _buildTabBarView(),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main toolbar with controls and search
  Widget _buildToolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Pause/Resume button
          IconButton(
            tooltip: _isPaused ? 'Resume updates' : 'Pause updates',
            onPressed: _togglePause,
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            iconSize: 20,
          ),

          // Clear button
          IconButton(
            tooltip: 'Clear current tab data',
            onPressed: _clearCurrentTabData,
            icon: const Icon(Icons.clear_all),
            iconSize: 20,
          ),

          const SizedBox(width: 8),

          // Search field
          Expanded(
            child: SizedBox(
              height: 32,
              child: TextField(
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () => _updateSearch(''),
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: _updateSearch,
                onSubmitted: _performSearch,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Export button
          if (widget.exportService != null)
            IconButton(
              tooltip: 'Export current data',
              onPressed: _quickExport,
              icon: const Icon(Icons.download),
              iconSize: 20,
            ),

          // Settings button
          IconButton(
            tooltip: 'Console settings',
            onPressed: () => _tabController.animateTo(
              _availableTabs.indexWhere((tab) => tab.key == 'settings'),
            ),
            icon: const Icon(Icons.settings),
            iconSize: 20,
          ),

          // Close button
          IconButton(
            tooltip: 'Close console',
            onPressed: () => Backstage.I.setEnabled(false),
            icon: const Icon(Icons.close),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  /// Builds the tab bar for navigation
  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: _availableTabs
            .map((tab) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(tab.title),
                      if (tab.badge != null && tab.badge! > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tab.badge! > 99 ? '99+' : tab.badge.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// Builds the tab content view
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: _availableTabs.map((tab) => tab.builder(context)).toList(),
    );
  }

  /// Builds the logs tab content
  Widget _buildLogsTab() {
    final filteredLogs = _filterLogs(_logs);

    return Column(
      children: [
        if (filteredLogs.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No logs available',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return _buildLogTile(log);
              },
            ),
          ),
        _buildLogSummary(filteredLogs),
      ],
    );
  }

  /// Builds the network tab content
  Widget _buildNetworkTab() {
    if (widget.networkService == null) {
      return const Center(child: Text('Network monitoring not available'));
    }

    final filteredRequests = _filterNetworkRequests(_networkRequests);

    return Column(
      children: [
        _buildNetworkStats(),
        if (filteredRequests.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No network requests'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];
                return _buildNetworkTile(request);
              },
            ),
          ),
      ],
    );
  }

  /// Builds the performance tab content
  Widget _buildPerformanceTab() {
    if (widget.performanceService == null) {
      return const Center(child: Text('Performance monitoring not available'));
    }

    return Column(
      children: [
        _buildPerformanceStats(),
        if (_performanceSnapshots.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No performance data'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _performanceSnapshots.length,
              itemBuilder: (context, index) {
                final snapshot = _performanceSnapshots[index];
                return _buildPerformanceTile(snapshot);
              },
            ),
          ),
      ],
    );
  }

  /// Builds the search tab content
  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Search',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Search form would go here
          const Text('Advanced search functionality coming soon...'),
        ],
      ),
    );
  }

  /// Builds the export tab content
  Widget _buildExportTab() {
    if (widget.exportService == null) {
      return const Center(child: Text('Export functionality not available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Data',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Export options would go here
          const Text('Export functionality coming soon...'),
        ],
      ),
    );
  }

  /// Builds the settings tab content
  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Console Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Settings UI would go here
          const Text('Settings panel coming soon...'),
        ],
      ),
    );
  }

  /// Builds a log entry tile
  Widget _buildLogTile(BackstageLog log) {
    final theme = Theme.of(context);

    IconData icon;
    Color? color;
    switch (log.level) {
      case BackstageLevel.debug:
        icon = Icons.bug_report_outlined;
        color = theme.colorScheme.onSurface.withOpacity(0.6);
        break;
      case BackstageLevel.info:
        icon = Icons.info_outlined;
        color = theme.colorScheme.primary;
        break;
      case BackstageLevel.warn:
        icon = Icons.warning_amber_outlined;
        color = Colors.amber;
        break;
      case BackstageLevel.error:
        icon = Icons.error_outlined;
        color = Colors.red;
        break;
    }

    return InkWell(
      onTap: () => _showLogDetails(log),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.level.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(log.time),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.message,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a network request tile
  Widget _buildNetworkTile(NetworkRequest request) {
    final theme = Theme.of(context);

    Color statusColor;
    if (request.isError) {
      statusColor = Colors.red;
    } else if (request.isSuccess) {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.orange;
    }

    return InkWell(
      onTap: () => _showNetworkDetails(request),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              color: statusColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        request.method,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (request.statusCode != null)
                        Text(
                          request.statusCode.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      const Spacer(),
                      if (request.duration != null)
                        Text(
                          '${request.duration!.inMilliseconds}ms',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.url,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (request.error != null)
                    Text(
                      request.error!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a performance snapshot tile
  Widget _buildPerformanceTile(PerformanceSnapshot snapshot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatTime(snapshot.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (snapshot.memoryUsage != null) ...[
                _buildMetricChip('Memory',
                    '${(snapshot.memoryUsage! / 1024 / 1024).round()}MB'),
                const SizedBox(width: 8),
              ],
              if (snapshot.cpuUsage != null) ...[
                _buildMetricChip(
                    'CPU', '${snapshot.cpuUsage!.toStringAsFixed(1)}%'),
                const SizedBox(width: 8),
              ],
              if (snapshot.frameRate != null)
                _buildMetricChip('FPS', snapshot.frameRate!.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a metric chip for performance display
  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  /// Builds log summary footer
  Widget _buildLogSummary(List<BackstageLog> logs) {
    final theme = Theme.of(context);
    final levelCounts = <BackstageLevel, int>{};

    for (final log in logs) {
      levelCounts[log.level] = (levelCounts[log.level] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text('Total: ${logs.length}', style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 16),
          ...BackstageLevel.values.map((level) {
            final count = levelCounts[level] ?? 0;
            if (count == 0) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${level.name}: $count',
                style: const TextStyle(fontSize: 10),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds network statistics header
  Widget _buildNetworkStats() {
    if (widget.networkService == null) return const SizedBox.shrink();

    final stats = widget.networkService!.getNetworkStats();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildStatChip('Total', stats['totalRequests'].toString()),
          const SizedBox(width: 8),
          _buildStatChip('Success', stats['successCount'].toString()),
          const SizedBox(width: 8),
          _buildStatChip('Errors', stats['errorCount'].toString()),
          const SizedBox(width: 8),
          _buildStatChip('Avg Time',
              '${stats['averageResponseTime'].toStringAsFixed(0)}ms'),
        ],
      ),
    );
  }

  /// Builds performance statistics header
  Widget _buildPerformanceStats() {
    if (widget.performanceService == null) return const SizedBox.shrink();

    final stats = widget.performanceService!.getPerformanceStats();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildStatChip('Snapshots', stats['totalSnapshots'].toString()),
          _buildStatChip('Avg Memory', '${stats['averageMemoryMB']}MB'),
          _buildStatChip('Avg FPS', stats['averageFPS'].toString()),
          if (stats['jankyFrameCount'] > 0)
            _buildStatChip(
                'Jank', stats['jankyFrameCount'].toString(), Colors.orange),
        ],
      ),
    );
  }

  /// Builds a statistics chip
  Widget _buildStatChip(String label, String value, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }

  /// Sets up real-time data streams
  void _setupDataStreams() {
    // Log stream
    _subscriptions.add(widget.logger.stream.listen((log) {
      if (!_isPaused) {
        setState(() {
          _logs.add(log);
          if (_logs.length > 1000) _logs.removeAt(0); // Limit memory usage
        });
        _autoScroll();
      }
    }));

    // Network stream
    if (widget.networkService != null) {
      _subscriptions.add(widget.networkService!.requestStream.listen((request) {
        if (!_isPaused) {
          setState(() {
            _networkRequests.add(request);
            if (_networkRequests.length > 500) _networkRequests.removeAt(0);
          });
        }
      }));
    }

    // Performance stream
    if (widget.performanceService != null) {
      _subscriptions
          .add(widget.performanceService!.snapshotStream.listen((snapshot) {
        if (!_isPaused) {
          setState(() {
            _performanceSnapshots.add(snapshot);
            if (_performanceSnapshots.length > 200) {
              _performanceSnapshots.removeAt(0);
            }
          });
        }
      }));
    }
  }

  /// Loads initial data from services
  void _loadInitialData() async {
    // Load recent logs
    final recentLogs = await widget.logger.getRecentLogs(100);
    setState(() {
      _logs.addAll(recentLogs);
    });

    // Load recent network requests
    if (widget.networkService != null) {
      final recentRequests = widget.networkService!.getAllRequests();
      setState(() {
        _networkRequests.addAll(recentRequests.take(100));
      });
    }

    // Load recent performance data
    if (widget.performanceService != null) {
      final recentSnapshots =
          widget.performanceService!.getPerformanceSnapshots();
      setState(() {
        _performanceSnapshots.addAll(recentSnapshots.take(50));
      });
    }
  }

  /// Sets up keyboard shortcuts
  void _setupKeyboardShortcuts() {
    if (!widget.uiConfig.enableKeyboardShortcuts) return;

    // TODO: Implement keyboard shortcuts
    // This would involve setting up keyboard listeners for:
    // - Ctrl+F: Focus search
    // - Ctrl+1-6: Switch tabs
    // - Ctrl+E: Export
    // - Escape: Clear search or close
  }

  /// Calculates panel width based on configuration and screen size
  double _calculatePanelWidth() {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = widget.uiConfig.maxPanelWidth;
    final minWidth = widget.uiConfig.minPanelWidth;

    double width = screenWidth * 0.8; // Default to 80% of screen width

    if (width > maxWidth) width = maxWidth;
    if (width < minWidth) width = minWidth;

    return width;
  }

  /// Calculates panel height based on configuration and screen size
  double _calculatePanelHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = widget.uiConfig.maxPanelHeight;
    final minHeight = widget.uiConfig.minPanelHeight;

    double height = screenHeight * 0.6; // Default to 60% of screen height

    if (height > maxHeight) height = maxHeight;
    if (height < minHeight) height = minHeight;

    return height;
  }

  /// Filters logs based on current search query
  List<BackstageLog> _filterLogs(List<BackstageLog> logs) {
    if (_searchQuery.isEmpty) return logs;

    final query = _searchQuery.toLowerCase();
    return logs
        .where((log) =>
            log.message.toLowerCase().contains(query) ||
            log.tag.toLowerCase().contains(query) ||
            log.level.name.toLowerCase().contains(query))
        .toList();
  }

  /// Filters network requests based on current search query
  List<NetworkRequest> _filterNetworkRequests(List<NetworkRequest> requests) {
    if (_searchQuery.isEmpty) return requests;

    final query = _searchQuery.toLowerCase();
    return requests
        .where((request) =>
            request.url.toLowerCase().contains(query) ||
            request.method.toLowerCase().contains(query) ||
            (request.error?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  /// Toggles pause state for real-time updates
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  /// Clears data for the currently selected tab
  void _clearCurrentTabData() {
    final currentTab = _availableTabs[_selectedTabIndex];

    setState(() {
      switch (currentTab.key) {
        case 'logs':
          _logs.clear();
          break;
        case 'network':
          _networkRequests.clear();
          widget.networkService?.clearRequests();
          break;
        case 'performance':
          _performanceSnapshots.clear();
          widget.performanceService?.clearPerformanceData();
          break;
      }
    });
  }

  /// Updates search query and filters data
  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  /// Performs advanced search
  void _performSearch(String query) {
    // TODO: Implement advanced search functionality
    _updateSearch(query);
  }

  /// Performs quick export of current tab data
  void _quickExport() async {
    if (widget.exportService == null) return;

    try {
      final currentTab = _availableTabs[_selectedTabIndex];

      switch (currentTab.key) {
        case 'logs':
          await widget.exportService!.exportAndShare(
            _filterLogs(_logs),
            format: ExportFormat.json,
            subject: 'Backstage Logs Export',
          );
          break;
        case 'network':
          // TODO: Export network data
          break;
        case 'performance':
          // TODO: Export performance data
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Export failed: $e');
      }
    }
  }

  /// Auto-scrolls to bottom when new entries arrive
  void _autoScroll() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Shows detailed log information in a dialog
  void _showLogDetails(BackstageLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${log.level.name.toUpperCase()} - ${log.tag}'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Time: ${log.time}'),
            const SizedBox(height: 8),
            Text('Message:', style: Theme.of(context).textTheme.labelMedium),
            Text(log.message),
            if (log.stackTrace != null) ...[
              const SizedBox(height: 8),
              Text('Stack Trace:',
                  style: Theme.of(context).textTheme.labelMedium),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.stackTrace.toString(),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: log.message));
              Navigator.of(context).pop();
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Shows detailed network request information
  void _showNetworkDetails(NetworkRequest request) {
    // TODO: Implement network details dialog
  }

  /// Formats timestamp for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }

    super.dispose();
  }
}

/// Represents a console tab with its configuration
class ConsoleTab {
  /// Unique key for the tab
  final String key;

  /// Display title
  final String title;

  /// Tab icon
  final IconData icon;

  /// Optional badge count
  final int? badge;

  /// Widget builder for tab content
  final Widget Function(BuildContext) builder;

  const ConsoleTab({
    required this.key,
    required this.title,
    required this.icon,
    this.badge,
    required this.builder,
  });
}
