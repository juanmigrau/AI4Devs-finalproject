import 'package:flutter/material.dart';
import 'package:la_pocha/core/theme/app_theme.dart';
import 'package:la_pocha/core/utils/player_colors.dart';
import 'package:la_pocha/features/game_setup/domain/entities/player_embed.dart';
import 'package:la_pocha/features/round/domain/entities/scorecard_row.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class ScorecardTable extends StatefulWidget {
  const ScorecardTable({
    super.key,
    required this.players,
    required this.rows,
  });

  final List<PlayerEmbed> players;
  final List<ScorecardRow> rows;

  @override
  State<ScorecardTable> createState() => _ScorecardTableState();
}

class _ScorecardTableState extends State<ScorecardTable> {
  static const double _stickyWidth = 40;
  static const double _playerBlockWidth = 72;
  static const double _rowHeight = 36;
  static const double _headerHeight = 36;

  late final LinkedScrollControllerGroup _horizontalGroup;
  late final ScrollController _headerHorizontal;
  late final ScrollController _bodyHorizontal;
  late final LinkedScrollControllerGroup _verticalGroup;
  late final ScrollController _cardsVertical;
  late final ScrollController _bodyVertical;

  @override
  void initState() {
    super.initState();
    _horizontalGroup = LinkedScrollControllerGroup();
    _headerHorizontal = _horizontalGroup.addAndGet();
    _bodyHorizontal = _horizontalGroup.addAndGet();
    _verticalGroup = LinkedScrollControllerGroup();
    _cardsVertical = _verticalGroup.addAndGet();
    _bodyVertical = _verticalGroup.addAndGet();
  }

  @override
  void dispose() {
    _headerHorizontal.dispose();
    _bodyHorizontal.dispose();
    _cardsVertical.dispose();
    _bodyVertical.dispose();
    super.dispose();
  }

  String _shortName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.length <= 3
        ? trimmed.toUpperCase()
        : trimmed.substring(0, 3).toUpperCase();
  }

  Color _dividerColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dividerColor = _dividerColor(context);
    final cellStyle = textTheme.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.1,
    );
    final headerStyle = textTheme.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _stickyWidth,
          child: Column(
            children: [
              Container(
                height: _headerHeight,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: dividerColor, width: 0.5),
                    bottom: BorderSide(color: dividerColor, width: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    '#',
                    style: headerStyle?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _cardsVertical,
                  child: Column(
                    children: [
                      for (final row in widget.rows)
                        _CardsCell(
                          height: _rowHeight,
                          cardsInRound: row.cardsInRound,
                          isCurrent: row.isCurrent,
                          style: cellStyle,
                          dividerColor: dividerColor,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                height: _headerHeight,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: dividerColor, width: 0.5),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: _headerHorizontal,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.players.length; i++)
                        _PlayerHeader(
                          width: _playerBlockWidth,
                          colorIndex: i,
                          shortName: _shortName(widget.players[i].displayName),
                          style: headerStyle,
                          showRightDivider: i < widget.players.length - 1,
                          dividerColor: dividerColor,
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _bodyHorizontal,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _playerBlockWidth * widget.players.length,
                    child: SingleChildScrollView(
                      controller: _bodyVertical,
                      child: Column(
                        children: [
                          for (final row in widget.rows)
                            _DataRow(
                              height: _rowHeight,
                              playerBlockWidth: _playerBlockWidth,
                              players: widget.players,
                              row: row,
                              style: cellStyle,
                              dividerColor: dividerColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardsCell extends StatelessWidget {
  const _CardsCell({
    required this.height,
    required this.cardsInRound,
    required this.isCurrent,
    required this.style,
    required this.dividerColor,
  });

  final double height;
  final int cardsInRound;
  final bool isCurrent;
  final TextStyle? style;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        border: Border(
          right: BorderSide(color: dividerColor, width: 0.5),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Text(
        '$cardsInRound',
        style: style?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.width,
    required this.colorIndex,
    required this.shortName,
    required this.style,
    required this.showRightDivider,
    required this.dividerColor,
  });

  final double width;
  final int colorIndex;
  final String shortName;
  final TextStyle? style;
  final bool showRightDivider;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final color = playerAvatarColorForIndex(colorIndex);
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: showRightDivider
          ? BoxDecoration(
              border: Border(
                right: BorderSide(color: dividerColor, width: 0.5),
              ),
            )
          : null,
      child: Text(
        shortName,
        style: style?.copyWith(color: color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.height,
    required this.playerBlockWidth,
    required this.players,
    required this.row,
    required this.style,
    required this.dividerColor,
  });

  final double height;
  final double playerBlockWidth;
  final List<PlayerEmbed> players;
  final ScorecardRow row;
  final TextStyle? style;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: row.isCurrent
            ? AppTheme.primary.withValues(alpha: 0.05)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < players.length; i++)
            Container(
              width: playerBlockWidth,
              decoration: i < players.length - 1
                  ? BoxDecoration(
                      border: Border(
                        right: BorderSide(color: dividerColor, width: 0.5),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatNullable(row.bids[players[i].id]),
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatNullable(row.cumulative[players[i].id]),
                      textAlign: TextAlign.center,
                      style: style?.copyWith(
                        color: _cumulativeColor(row.cumulative[players[i].id]),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatNullable(int? value) => value == null ? '—' : '$value';

  Color? _cumulativeColor(int? value) {
    if (value == null) {
      return AppTheme.onSurfaceVariant;
    }
    if (value < 0) {
      return const Color(0xFFB3261E);
    }
    if (value > 0) {
      return AppTheme.primary;
    }
    return AppTheme.onSurface;
  }
}
