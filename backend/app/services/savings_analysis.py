ESSENTIAL_CATEGORY_NAMES = {"moradia", "saúde", "contas fixas"}


def is_essential_category(name: str) -> bool:
    return name.strip().lower() in ESSENTIAL_CATEGORY_NAMES
