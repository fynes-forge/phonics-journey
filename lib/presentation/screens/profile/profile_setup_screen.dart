import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/profile/profile_bloc.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isEditing;
  const ProfileSetupScreen({super.key, this.isEditing = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  Color _selectedColor = AppTheme.profileColors[0];
  int _selectedAvatar = 0;
  bool _hasLoadedInitialData = false;
  
  // We hold a direct reference to the singleton to avoid context-based disposal errors
  late final ProfileBloc _profileBloc;

  final List<String> _avatarEmojis = [
    '🚀', '⭐', '🌙', '🪐', '☄️', '🌟', '🛸', '🌈',
  ];

  @override
  void initState() {
    super.initState();
    // Use the Service Locator directly to ensure we have the persistent Singleton
    _profileBloc = GetIt.I<ProfileBloc>();
    
    if (widget.isEditing) {
      _profileBloc.add(LoadActiveProfile());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    // DO NOT call _profileBloc.close() here. 
    // It is a singleton and must live for the life of the app.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      bloc: _profileBloc, // Explicitly pass the bloc instance
      listener: (context, state) {
        if (state is ProfileLoaded) {
          if (widget.isEditing && !_hasLoadedInitialData) {
            // Initial data fill
            _nameController.text = state.profile.name;
            _selectedColor = Color(state.profile.themeColorValue);
            _selectedAvatar = state.profile.avatarIndex;
            _hasLoadedInitialData = true;
            setState(() {});
          } else if (_hasLoadedInitialData || !widget.isEditing) {
            // A ProfileLoaded state after a submission triggers navigation
            context.go(AppRouter.planetPath);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: AppTheme.spaceBackground,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    Text(
                      widget.isEditing ? 'Edit Your Profile' : 'Welcome, Explorer!',
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3),

                    const SizedBox(height: 8),

                    Text(
                      widget.isEditing
                          ? 'Update your space explorer details'
                          : 'Let\'s set up your space adventure!',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.starYellow,
                      ),
                      textAlign: TextAlign.center,
                    ).animate(delay: 200.ms).fadeIn(),

                    const SizedBox(height: 40),

                    Text(
                      'Choose your explorer!',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ).animate(delay: 300.ms).fadeIn(),

                    const SizedBox(height: 16),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(_avatarEmojis.length, (i) {
                        final selected = _selectedAvatar == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: selected
                                  ? _selectedColor.withOpacity(0.3)
                                  : AppTheme.stardustBlue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? _selectedColor : Colors.white24,
                                width: selected ? 3 : 1,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: _selectedColor.withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                _avatarEmojis[i],
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: 350 + i * 50))
                            .fadeIn()
                            .scale(begin: const Offset(0.8, 0.8));
                      }),
                    ),

                    const SizedBox(height: 36),

                    Text(
                      'What\'s your name?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ).animate(delay: 500.ms).fadeIn(),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontFamily: 'Andika',
                        fontSize: 22,
                        color: AppTheme.moonWhite,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type your name here...',
                        prefixIcon: Center(
                          widthFactor: 1.0,
                          child: Text(
                            _avatarEmojis[_selectedAvatar],
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ).animate(delay: 550.ms).fadeIn().slideX(begin: -0.2),

                    const SizedBox(height: 36),

                    Text(
                      'Pick your planet colour!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ).animate(delay: 650.ms).fadeIn(),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: AppTheme.profileColors.map((color) {
                        final selected = _selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: selected ? 52 : 44,
                            height: selected ? 52 : 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.6),
                                        blurRadius: 16,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check, color: Colors.white, size: 22)
                                : null,
                          ),
                        );
                      }).toList(),
                    ).animate(delay: 700.ms).fadeIn(),

                    const SizedBox(height: 48),

                    if (_nameController.text.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.cardDecoration(glowColor: _selectedColor),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _avatarEmojis[_selectedAvatar],
                              style: const TextStyle(fontSize: 36),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                _nameController.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: _selectedColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                      const SizedBox(height: 24),
                    ],

                    ElevatedButton(
                      onPressed: _canProceed()
                          ? () => _handleSubmit(context, state)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: state is ProfileLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.isEditing ? 'Save Changes' : 'Start My Journey!',
                                  style: const TextStyle(
                                    fontFamily: 'Andika',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(widget.isEditing ? '✅' : '🚀', style: const TextStyle(fontSize: 20)),
                              ],
                            ),
                    ).animate(delay: 800.ms).fadeIn().scale(
                          begin: const Offset(0.9, 0.9),
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canProceed() => _nameController.text.trim().isNotEmpty;

  void _handleSubmit(BuildContext context, ProfileState state) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // The Fix: Check if the bloc is closed before attempting to add an event
    if (_profileBloc.isClosed) {
      debugPrint('🚨 CRITICAL ERROR: ProfileBloc is closed. This should not happen to a Singleton.');
      return;
    }

    if (widget.isEditing && state is ProfileLoaded) {
      _profileBloc.add(
        UpdateProfileEvent(
          state.profile.copyWith(
            name: name,
            themeColorValue: _selectedColor.value,
            avatarIndex: _selectedAvatar,
          ),
        ),
      );
    } else {
      _profileBloc.add(
        CreateProfile(
          name: name,
          themeColor: _selectedColor,
          avatarIndex: _selectedAvatar,
        ),
      );
    }
  }
}