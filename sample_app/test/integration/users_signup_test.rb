require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  def setup
    ActionMailer::Base.deliveries.clear                                         # Mailerファイルを初期化しユーザーをセットアップ
  end

  test "invalid signup information" do                                          # 新規登録が失敗（フォーム送信が）した時用のテスト
    get signup_path                                                             # ユーザー登録ページにアクセス
    assert_no_difference 'User.count' do                                        # User.countでユーザー数が変わっていなければ（ユーザー生成失敗）true,変わっていればfalse
    post signup_path, params: { user: {    name: "",                             # signup_pathからusers_pathに対してpostリクエスト送信(/usersへ)、paramsでuserハッシュとその下のハッシュで値を受け取れるか確認
                                          email: "user@invalid",
                                          password:              "foo",
                                          password_confirmation: "bar" } }
    end
  assert_template 'users/new'                                                   # newアクションが描画(つまり@user.save失敗)されていればtrue、なければfalse
  assert_select   'div#error_explanation'                                       # divタグの中のid error_explanationが描画されていれば成功
  assert_select   'div.field_with_errors'                                       # divタグの中のclass field_with_errorsが描画されていれば成功
  assert_select   'form[action="/signup"]'                                      # formタグの中に`/signup`があれば成功

  end

  test "valid signup information with account activation" do                    # 新規登録が成功（フォーム送信）したかのテスト
    get signup_path                                                             # signup_path(/signup)ユーザー登録ページにアクセス
    assert_difference 'User.count', 1 do                                        # User.countでユーザー数をカウント、1とし、ユーザー数が変わったらtrue、変わってなければfalse
      post users_path, params: { user: { name:                 "Example User",  # signup_path(/signup)からusers_path(/users)へparamsハッシュのuserハッシュの値を送れるか検証
                                        email:                 "user@example.com",
                                        password:              "password",
                                        password_confirmation: "password" } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size                          # Actionメイラーが1かどうか検証
    user = assigns(:user)                                                       # usersコントローラの@userにアクセスし、userに代入
    assert_not user.activated?                                                  # userが有効化されていればfalse、されていなければtrue
    # 有効化していない状態でログインしてみる 
    log_in_as(user)                                                             # 有効化されていないuserでログイン
    assert_not is_logged_in?                                                    # 有効化されていなければtrue
    # 有効化トークンが不正な場合
    get edit_account_activation_path("invalid token", email: user.email)
    assert_not is_logged_in?
    # トークンは正しいがメールアドレスが無効な場合
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not is_logged_in?
    # 有効化トークンが正しい場合
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!                                                            # 指定されたリダイレクト先(users/show)へ飛べるか検証
    assert_template 'users/show'                                                # users/showが描画されているか確認
    assert is_logged_in?                                                        # 新規登録時にセッションが空じゃなければtrue
  end

end