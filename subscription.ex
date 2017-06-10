defmodule David.Subscription do
    alias David.User
    import Ecto.Changeset, only: [put_change: 3]

    def create(user, card_token, plan, repo) do
        case subscribe_customer(card_token, plan) do
            {:ok, sub_id, active_until} ->
                user
                |> User.nonpass_changeset
                |> put_change(:sub_id, sub_id)
                |> put_change(:membership, plan)
                |> put_change(:active_until, active_until)
                |> repo.update
            {:error, message} ->
                {:error, message}
        end
    end

    def subscribe_customer(card_token, plan) do
        case Stripe.Subscriptions.create card_token, [plan: "Premium"] do
            {:ok, response} ->
                sub_id = response[:id]
                active_until = response[:current_period_end] |> Timex.from_unix
                {:ok, sub_id, active_until}
            {:error, message} ->
                {:error, message}
        end
    end

    def cancel_subscription(card_token, sub_id) do
        case Stripe.Subscriptions.cancel card_token, sub_id, [at_period_end: true] do
            {:ok, deleted} ->
                {:ok, deleted}
            {:error, message} ->
                {:error, message}
        end
    end
    
    def delete(user, card_token, sub_id, repo) do
        case cancel_subscription card_token, user.sub_id do
            {:ok, deleted} ->
                user
                |> User.nonpass_changeset
                # |> put_change(:sub_id, "")
                # |> put_change(:card_token, "")
                |> put_change(:membership, "Free")
                |> repo.update
            {:error, message} ->
                {:error, message}
        end
            
    end

    def hook_cancel(user, repo) do
        user
        |> User.nonpass_changeset
        |> put_change(:sub_id, nil)
        |> put_change(:card_token, nil)
        |> put_change(:membership, "Free")
        |> repo.update
    end
end