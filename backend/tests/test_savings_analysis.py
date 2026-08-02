from app.services.savings_analysis import is_essential_category


def test_is_essential_category_matches_known_names():
    assert is_essential_category("Moradia") is True
    assert is_essential_category("Saúde") is True
    assert is_essential_category("Contas fixas") is True


def test_is_essential_category_case_insensitive():
    assert is_essential_category("moradia") is True
    assert is_essential_category("SAÚDE") is True
    assert is_essential_category("contas FIXAS") is True


def test_is_essential_category_unknown_name_is_not_essential():
    assert is_essential_category("Alimentação") is False
    assert is_essential_category("Pet") is False
    assert is_essential_category("Assinaturas") is False
