defmodule David.SubscribeController do
    use David.Web, :controller

    alias David.User

    def action(conn, _) do
        apply(__MODULE__, action_name(conn),
          [conn, conn.params, conn.assigns.current_user])
    end

    def index(conn, _params, current_user) do
        user = Repo.get!(User, current_user.id)
        changeset = User.changeset(%User{})
        render(conn, "show.html", user: user, changeset: changeset)
    end

    def new(conn, _params, current_user) do
        changeset = User.changeset(%User{})
        render(conn, "new.html", changeset: changeset)
    end

    def create(conn, %{"user" => subscribe_params, "stripeToken" => token}, current_user) do
        user = Repo.get(User, current_user.id)

        case David.Customer.create(user, token, David.Repo) do
            {:ok, card_token} -> 
                David.Subscription.create(user, card_token, "Premium", David.Repo)
                conn
                |> put_flash(:info, "Subscribed Succesfully, Welcome!")
                |> redirect(to: user_path(conn, :show, user))
            {:error, message} ->
                conn
                |> put_flash(:error, "#{message["error"]["message"]}")
                |> redirect(to: subscribe_path(conn, :index))
        end

    end

    def show(conn, %{"id" => id}, current_user) do
        user = Repo.get!(User, current_user.id)
        changeset = User.changeset(user)
        render(conn, "show.html", user: user, changeset: changeset)
    end

    def edit(conn, %{"id" => id}, current_user) do
        user = Repo.get(User, current_user.id)
        changeset = User.changeset(user)
        render(conn, "edit.html", user: user, changeset: changeset)
    end

    def update(conn, %{"user" => subscribe_params}, current_user) do
        user = Repo.get(User, current_user.id)
        changeset = User.changeset(user, subscribe_params)

        case Stripe.Subscriptions.change user.card_token, user.sub_id, [plan: subscribe_params["membership"]] do
            {:ok, plan} ->
                plan
                changeset = Map.put(changeset, "membership", subscribe_params["membership"])
            {:error, message} ->
                # render(conn, "edit.html", changeset: changeset, user: user)
                conn
                |> put_flash(:info, "#{message["error"]["message"]}")
                |> redirect(to: subscribe_path(conn, :edit, current_user.id))
        end
        


        case Repo.update(changeset) do
            {:ok, _params} ->
                conn
                |> put_flash(:info, "Subscribed successfully.")
                |> redirect(to: user_path(conn, :show, user))
            {:error, changeset} ->
                render(conn, "edit.html", changeset: changeset, user: user)
        end
    end

  def delete(conn, _params, current_user) do
    user = Repo.get(User, current_user.id)

    case David.Subscription.delete(user, user.card_token, user.sub_id, David.Repo) do
        {:ok, deleted} ->
            conn
            |> put_flash(:info, "Subscription cancelled successfully.")
            |> redirect(to: subscribe_path(conn, :index))
        {:error, message} ->
            conn
            |> put_flash(:error, message)
            |> redirect(to: subscribe_path(conn, :index))
        end
    end
    
end


