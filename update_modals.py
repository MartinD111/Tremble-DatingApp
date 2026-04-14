import re

with open("temp_modals.txt", "r", encoding="utf-8") as f:
    text = f.read()

# Add imports
text = text.replace("import 'package:lucide_icons/lucide_icons.dart';",
                    "import 'package:lucide_icons/lucide_icons.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../../../shared/ui/discard_changes_modal.dart';\nimport '../../../shared/ui/top_notification.dart';\nimport '../../auth/data/auth_repository.dart';\nimport '../../../core/translations.dart';")

# Convert StatefulWidget -> ConsumerStatefulWidget
text = text.replace("class _PreferenceEditSheet extends StatefulWidget", "class _PreferenceEditSheet extends ConsumerStatefulWidget")
text = text.replace("class _SliderEditSheet extends StatefulWidget", "class _SliderEditSheet extends ConsumerStatefulWidget")
text = text.replace("class _MultiSelectEditSheet extends StatefulWidget", "class _MultiSelectEditSheet extends ConsumerStatefulWidget")
text = text.replace("class _LanguageEditSheet extends StatefulWidget", "class _LanguageEditSheet extends ConsumerStatefulWidget")

text = text.replace("State<_PreferenceEditSheet>", "ConsumerState<_PreferenceEditSheet>")
text = text.replace("State<_SliderEditSheet>", "ConsumerState<_SliderEditSheet>")
text = text.replace("State<_MultiSelectEditSheet>", "ConsumerState<_MultiSelectEditSheet>")
text = text.replace("State<_LanguageEditSheet>", "ConsumerState<_LanguageEditSheet>")

# We will apply a PopScope wrapping and TopNotification manually using regex

def inject_popscope_and_save(class_name, has_changes_expr, save_expr):
    global text
    # find build function start
    
    # 1. replace `return Container(` with `return PopScope(`
    # This requires finding the build method of the specific class state.
    # We will regex to find the `Widget build` inside the class.
    
    pattern = rf"(class {class_name}State.*?)(Widget build\(BuildContext context\) {{)(.*?)(return Container\()"
    
    def replacer(m):
        pre_build = m.group(1)
        build_start = m.group(2)
        build_body = m.group(3)
        return_stmt = m.group(4)
        
        has_changes_method = f"  bool _hasChanges() => {has_changes_expr};\n\n"
        
        pop_scope_wrap = f"""
    final hasChanges = _hasChanges();
{return_stmt}"""
        
        # We need to find `onPressed:` of the save button and cancel button.
        # It's easier just to inject _hasChanges method before build.
        return pre_build + has_changes_method + build_start + build_body + """
    final hasChanges = _hasChanges();
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await showDiscardChangesModal(context, ref);
        if (res == 'save') {
""" + save_expr + """
        } else if (res == 'discard') {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Container("""
    
    text = re.sub(pattern, replacer, text, flags=re.DOTALL)
    
    # Inject TopNotification into the Save Button's onPressed:
    # Need to find the Save button for this class
    # Inside the class, find `Expanded(\n *child: ElevatedButton(... \n *onPressed: () { ... }`
    # or `onPressed: _selected != null ? () => widget.onSave... : null`
    
    save_btn_pattern = rf"({class_name}State.*?)(ElevatedButton\(\s*style: ElevatedButton\.styleFrom\(.*?\),\s*onPressed:\s*)(.*?)(\s*,\s*child: const Text\('Save')"
    
    def btn_replacer(m):
        start = m.group(1)
        btn_start = m.group(2)
        on_pressed = m.group(3)
        btn_end = m.group(4)
        
        # rewrite on_pressed
        new_on_pressed = ""
        if class_name == "_PreferenceEditSheet":
            new_on_pressed = """() {
                    widget.onUpdate(_pending == '__none__' ? null : _pending);
                    final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
                    TopNotification.show(
                      context: context,
                      message: t('profile_updated', lang),
                      icon: LucideIcons.checkCircle,
                    );
                    Navigator.pop(context);
                  }"""
        elif class_name == "_SliderEditSheet":
            new_on_pressed = """() {
                    widget.onSave(_values);
                    final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
                    TopNotification.show(
                      context: context,
                      message: t('profile_updated', lang),
                      icon: LucideIcons.checkCircle,
                    );
                    Navigator.pop(context);
                  }"""
        elif class_name == "_MultiSelectEditSheet":
            new_on_pressed = """() {
                    widget.onSave(_selected);
                    final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
                    TopNotification.show(
                      context: context,
                      message: t('profile_updated', lang),
                      icon: LucideIcons.checkCircle,
                    );
                    Navigator.pop(context);
                  }"""
        elif class_name == "_LanguageEditSheet":
            new_on_pressed = """_selected != null ? () {
                    widget.onSave(_selected!);
                    final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
                    TopNotification.show(
                      context: context,
                      message: t('profile_updated', lang),
                      icon: LucideIcons.checkCircle,
                    );
                    Navigator.pop(context);
                  } : null"""
                  
        return start + btn_start + new_on_pressed + btn_end
        
    text = re.sub(save_btn_pattern, btn_replacer, text, flags=re.DOTALL)


inject_popscope_and_save(
    "_PreferenceEditSheet", 
    "_pending != widget.currentValue",
    """          widget.onUpdate(_pending == '__none__' ? null : _pending);
          final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
          TopNotification.show(
            context: context,
            message: t('profile_updated', lang),
            icon: LucideIcons.checkCircle,
          );
          if (context.mounted) Navigator.pop(context);"""
)

inject_popscope_and_save(
    "_SliderEditSheet",
    "_values != widget.current",
    """          widget.onSave(_values);
          final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
          TopNotification.show(
            context: context,
            message: t('profile_updated', lang),
            icon: LucideIcons.checkCircle,
          );
          if (context.mounted) Navigator.pop(context);"""
)

def array_compare():
    pass

# For MultiSelect, list equality requires collection logic, let's just do a string join compare or `_selected.join() != widget.currentValues.join()`
has_changes_multi = "(_selected..sort()).join(',') != (List<String>.from(widget.currentValues)..sort()).join(',')"

inject_popscope_and_save(
    "_MultiSelectEditSheet",
    has_changes_multi,
    """          widget.onSave(_selected);
          final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
          TopNotification.show(
            context: context,
            message: t('profile_updated', lang),
            icon: LucideIcons.checkCircle,
          );
          if (context.mounted) Navigator.pop(context);"""
)

inject_popscope_and_save(
    "_LanguageEditSheet",
    "_selected != widget.currentValue && _selected != null",
    """          widget.onSave(_selected!);
          final lang = ref.read(authStateProvider)?.appLanguage ?? 'en';
          TopNotification.show(
            context: context,
            message: t('profile_updated', lang),
            icon: LucideIcons.checkCircle,
          );
          if (context.mounted) Navigator.pop(context);"""
)


# Also need to close PopScope `)` for each `return PopScope( ... child: Container( ... ), );`
# Since Container is returned, it ends with `    );\n  }` inside build function.
# Let's replace `    );\n  }\n}` with `    ),\n    );\n  }\n}`
# Actually, the best way is:
text = re.sub(r'(      \),\n    \);\n  \}\n\})', r'        ),\n      ),\n    );\n  }\n}', text) 
# wait, Container ends with `    );\n  }\n}` for the build method.
# Let's write a python function to find the matching `)` for PopScope.
# The simplest is replacing `    );\n  }\n}` with `    ),\n    );\n  }\n}`

text = text.replace("    );\n  }\n}", "    ),\n    );\n  }\n}")

# We should make sure `_none` is available in PopScope. It's inside the State class so it is.

with open("temp_modals2.dart", "w", encoding="utf-8") as f:
    f.write(text)
